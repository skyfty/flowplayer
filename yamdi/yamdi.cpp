#include "getopt.h"
#undef __STDC__
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>
#include <time.h>

#include "yamdi.h"

#define YAMDI_VERSION			"1.9"

#define FLV_SIZE_HEADER			9
#define FLV_SIZE_PREVIOUSTAGSIZE	4
#define FLV_SIZE_TAGHEADER		11

#define FLV_TAG_AUDIO			8
#define FLV_TAG_VIDEO			9
#define FLV_TAG_SCRIPTDATA		18

#define FLV_PACKET_H263VIDEO		2
#define FLV_PACKET_SCREENVIDEO		3
#define	FLV_PACKET_VP6VIDEO		4
#define	FLV_PACKET_VP6ALPHAVIDEO	5
#define FLV_PACKET_SCREENV2VIDEO	6
#define FLV_PACKET_H264VIDEO		7

#define FLV_UI32(x) (unsigned int)(((*(x)) << 24) + ((*(x + 1)) << 16) + ((*(x + 2)) << 8) + (*(x + 3)))
#define FLV_UI24(x) (unsigned int)(((*(x)) << 16) + ((*(x + 1)) << 8) + (*(x + 2)))
#define FLV_UI16(x) (unsigned int)(((*(x)) << 8) + (*(x + 1)))
#define FLV_UI8(x) (unsigned int)(*(x))
#define FLV_TIMESTAMP(x) (int)(((*(x + 3)) << 24) + ((*(x)) << 16) + ((*(x + 1)) << 8) + (*(x + 2)))

typedef struct {
	unsigned char *data;
	size_t size;
	size_t used;
} buffer_t;

typedef struct {
	__int64 offset;			// Offset from the beginning of the file

	// FLV spec v10
	unsigned int tagtype;
	size_t datasize;		// Size of the data contained in this tag
	int timestamp;
	short keyframe;			// Is this tag a keyframe?

	size_t tagsize;		// Size of the whole tag including header and data
} FLVTag_t;

typedef struct {
	size_t nflvtags;
	FLVTag_t *flvtag;
} FLVIndex_t;

typedef struct {
	FLVIndex_t index;

	int hascuepoints;
	int canseektoend;			// Set to 1 if the last video frame is a keyframe

	short hasaudio;
	struct {
		short analyzed;			// Are the audio specs complete and valid?

		// Audio specs
		short codecid;
		short samplerate;
		short samplesize;
		short delay;
		short stereo;

		// Calculated values
		size_t ntags;			// # of audio tags
		double datarate;		// datasize / duration
		uint64_t datasize;		// Size of the audio data
		uint64_t size;			// Size of the audio tags (header + data)
		int keyframerate;		// Store every x tags a keyframe. Only used for -a
		int keyframedistance;		// The time between two keyframes. Only used for -a

		int lasttimestamp;
		size_t lastframeindex;
	} audio;

	short hasvideo;
	struct {
		short analyzed;			// Are the video specs complete and valid?

		// Video specs
		short codecid;
		int height;
		int width;

		// Calculated values
		size_t ntags;			// # of video tags
		double framerate;		// ntags / duration
		double datarate;		// datasize / duration
		uint64_t datasize;		// Size of the video data
		uint64_t size;			// Size of the video tags (header + data)

		int lasttimestamp;
		size_t lastframeindex;
	} video;

	short haskeyframes;
	struct {
		size_t lastkeyframeindex;
		int lastkeyframetimestamp;
		__int64 lastkeyframelocation;

		size_t nkeyframes;		// # of key frames
		__int64 *keyframelocations;	// Array of the filepositions of the keyframes (in the target file!)
		int *keyframetimestamps;	// Array of the timestamps of the keyframes
	} keyframes;

	short hascipherkey;
	double cipherkey;

	uint64_t datasize;			// Size of all audio and video tags (header + data + FLV_SIZE_PREVIOUSTAGSIZE)
	uint64_t filesize;			// [sic!]

	int lasttimestamp;

	int lastsecond;
	size_t lastsecondindex;

	struct {
		char creator[256];		// -c

		short addonmetadata;		// defaults to 1, -M does change it
		short overwriteinput;		// -w
	} options;

	buffer_t onmetadata;
	buffer_t onlastkeyframe;
	buffer_t onlastsecond;
} FLV_t;

typedef struct {
	unsigned char *bytes;
	size_t length;
	size_t byte;
	short bit;
} bitstream_t;

typedef struct {
	short valid;
	int width;
	int height;
} h264data_t;

int validateFLV(FILE *fp);
int initFLV(FLV_t *flv);
int indexFLV(FLV_t *flv, FILE *fp);
int finalizeFLV(FLV_t *flv, FILE *fp);
int writeFLV(FILE *out, FLV_t *flv, FILE *fp);
int freeFLV(FLV_t *flv);

void storeFLVFromStdin(FILE *fp);
int readFLVTag(FLVTag_t *flvtag, __int64 offset, FILE *fp);
int readFLVTagData(unsigned char *ptr, size_t size, FLVTag_t *flvtag, FILE *stream);

int analyzeFLV(FLV_t *flv, FILE *fp);

int createFLVEventOnMetaData(FLV_t *flv);

int writeBufferFLVScriptDataTag(buffer_t *buffer, int timestamp, size_t datasize);
int writeBufferFLVPreviousTagSize(buffer_t *buffer, size_t tagsize);
int writeBufferFLVScriptDataValueArray(buffer_t *buffer, const char *name, size_t len);
int writeBufferFLVScriptDataECMAArray(buffer_t *buffer, const char *name, size_t len);
int writeBufferFLVScriptDataVariableArray(buffer_t *buffer, const char *name);
int writeBufferFLVScriptDataVariableArrayEnd(buffer_t *buffer);
int writeBufferFLVScriptDataValueString(buffer_t *buffer, const char *name, const char *value);
int writeBufferFLVScriptDataValueBool(buffer_t *buffer, const char *name, int value);
int writeBufferFLVScriptDataValueDouble(buffer_t *buffer, const char *name, double value);
int writeBufferFLVScriptDataObject(buffer_t *buffer);
int writeBufferFLVScriptDataString(buffer_t *buffer, const char *s);
int writeBufferFLVScriptDataLongString(buffer_t *buffer, const char *s);
int writeBufferFLVBool(buffer_t *buffer, int value);
int writeBufferFLVDouble(buffer_t *buffer, double v);

int writeFLVHeader(FILE *fp, int hasaudio, int hasvideo);
int writeFLVDataTag(FILE *fp, int type, int timestamp, size_t datasize, FLV_t *flv);
int writeFLVPreviousTagSize(FILE *fp, size_t tagsize, bool encry, FLV_t *flv);

int readBytes(unsigned char *ptr, size_t size, FILE *stream);

int readBits(bitstream_t *bitstream, int nbits);
int readBit(bitstream_t *bitstream);

int bufferInit(buffer_t *buffer);
int bufferFree(buffer_t *buffer);
int bufferReset(buffer_t *buffer);
int bufferAppendBuffer(buffer_t *dst, buffer_t *src);
int bufferAppendString(buffer_t *dst, const unsigned char *string);
int bufferAppendBytes(buffer_t *dst, const unsigned char *bytes, size_t nbytes);

int isBigEndian(void);

void initCipherCode(FLV_t *flv, const char *cipherkey);
void encryptionFLV(unsigned char *buf, int len, int key);

void printUsage(void);

int main(int argc, char **argv) {
	FILE *fp_infile = NULL, *fp_outfile = NULL;
	int c, unlink_infile = 0;
	char *infile, *outfile, *creator, *cipherkeybuf;
	FLV_t flv;

	infile = NULL;
	outfile = NULL;
	creator = NULL;
	cipherkeybuf = NULL;

	initFLV(&flv);

	while((c = getopt(argc, argv, ":i:o:e:x:c:h")) != -1) {
		switch(c) {
		case 'i':
			infile = optarg;
			break;
		case 'o':
			outfile = optarg;
			break;
		case 'e':
			cipherkeybuf = optarg;
			break;
		case 'c':
			strncpy(flv.options.creator, optarg, sizeof(flv.options.creator));
			break;
		default:
			printUsage();
			exit(YAMDI_ERROR);
			break;
		}
	}

	if(infile == NULL) {
		fprintf(stderr, "Please use -i to provide an input file. -h for help.\n");
		exit(YAMDI_ERROR);
	}

	if(outfile == NULL) {
		fprintf(stderr, "Please use -o to provide at least one output file. -h for help.\n");
		exit(YAMDI_ERROR);
	}

	if (cipherkeybuf != NULL) {
		initCipherCode(&flv, cipherkeybuf);
	}

	// Check input file
	fp_infile = fopen(infile, "rb");
	if(fp_infile == NULL) {
		exit(YAMDI_ERROR);
	}

	// Check if we have a valid FLV file
	if(validateFLV(fp_infile) != YAMDI_OK) {
		fclose(fp_infile);
		exit(YAMDI_ERROR);
	}

	// Open the outfile
	fp_outfile = NULL;
	if(outfile != NULL) {
		if(strcmp(outfile, "-")) {
			fp_outfile = fopen(outfile, "wb");
			if(fp_outfile == NULL) {
				fprintf(stderr, "Couldn't open %s.\n", outfile);
				exit(YAMDI_ERROR);
			}
		}
		else
			fp_outfile = stdout;
	}

	// Check the options
	flv.options.addonmetadata = 1;

	// Create an index of the FLV file
	if(indexFLV(&flv, fp_infile) != YAMDI_OK) {
		fclose(fp_infile);
		exit(YAMDI_ERROR);
	}

 	if(analyzeFLV(&flv, fp_infile) != YAMDI_OK) {
		fclose(fp_infile);
		exit(YAMDI_ERROR);
	}

	if(finalizeFLV(&flv, fp_infile) != YAMDI_OK) {
		fclose(fp_infile);
		exit(YAMDI_ERROR);
	}


	if(fp_outfile != NULL)
		writeFLV(fp_outfile, &flv, fp_infile);

	fclose(fp_infile);

	if(fp_outfile != NULL && fp_outfile != stdout)
		fclose(fp_outfile);

	freeFLV(&flv);

	return YAMDI_OK;
}

int validateFLV(FILE *fp) {
	unsigned char buffer[FLV_SIZE_HEADER + FLV_SIZE_PREVIOUSTAGSIZE];

	_fseeki64(fp, 0, SEEK_END);
	__int64 filesize = _ftelli64(fp);

	// Check for minimal FLV file length
	if(filesize < (FLV_SIZE_HEADER + FLV_SIZE_PREVIOUSTAGSIZE))
		return YAMDI_FILE_TOO_SMALL;

	rewind(fp);

	if(readBytes(buffer, FLV_SIZE_HEADER + FLV_SIZE_PREVIOUSTAGSIZE, fp) != YAMDI_OK)
		return YAMDI_READ_ERROR;

	// Check the FLV signature
	if(buffer[0] != 'F' || buffer[1] != 'L' || buffer[2] != 'V')
		return YAMDI_INVALID_SIGNATURE;

	// Check the FLV version
	if(FLV_UI8(&buffer[3]) != 1)
		return YAMDI_INVALID_FLVVERSION;

	// Check the DataOffset
	if(FLV_UI32(&buffer[5]) != FLV_SIZE_HEADER)
		return YAMDI_INVALID_DATASIZE;

	// Check the PreviousTagSize0 value
	if(FLV_UI32(&buffer[FLV_SIZE_HEADER]) != 0)
		return YAMDI_INVALID_PREVIOUSTAGSIZE;

	return YAMDI_OK;
}

int initFLV(FLV_t *flv) {
	if(flv == NULL)
		return YAMDI_ERROR;

	memset(flv, 0, sizeof(FLV_t));
	return YAMDI_OK;
}

int indexFLV(FLV_t *flv, FILE *fp) {
	__int64 offset;
	size_t nflvtags;
	FLVTag_t flvtag;

	// Count how many tags are there in this FLV
	offset = FLV_SIZE_HEADER + FLV_SIZE_PREVIOUSTAGSIZE;
	nflvtags = 0;
	while(readFLVTag(&flvtag, offset, fp) == YAMDI_OK) {
		offset += (flvtag.tagsize + FLV_SIZE_PREVIOUSTAGSIZE);

		nflvtags++;
	}

	flv->index.nflvtags = nflvtags;

	if(nflvtags == 0)
		return YAMDI_OK;

	// Allocate memory for the tag metadata index
	flv->index.flvtag = (FLVTag_t *)calloc(flv->index.nflvtags, sizeof(FLVTag_t));
	if(flv->index.flvtag == NULL)
		return YAMDI_OUT_OF_MEMORY;

	// Store the tag metadata in the index
	offset = FLV_SIZE_HEADER + FLV_SIZE_PREVIOUSTAGSIZE;
	nflvtags = 0;
	while(readFLVTag(&flvtag, offset, fp) == YAMDI_OK) {
		flv->index.flvtag[nflvtags].offset = flvtag.offset;
		flv->index.flvtag[nflvtags].tagtype = flvtag.tagtype;
		flv->index.flvtag[nflvtags].datasize = flvtag.datasize;
		flv->index.flvtag[nflvtags].timestamp = flvtag.timestamp;
		flv->index.flvtag[nflvtags].tagsize = flvtag.tagsize;
		offset += (flv->index.flvtag[nflvtags].tagsize + FLV_SIZE_PREVIOUSTAGSIZE);
		nflvtags++;
	}

	return YAMDI_OK;
}

void storeFLVFromStdin(FILE *fp) {
	char buf[4096];
	size_t bytes;

	while((bytes = fread(buf, 1, sizeof(buf), stdin)) > 0)
		fwrite(buf, 1, bytes, fp);
}

int freeFLV(FLV_t *flv) {
	if(flv->index.nflvtags != 0)
		free(flv->index.flvtag);

	if(flv->keyframes.keyframelocations != NULL)
		free(flv->keyframes.keyframelocations);

	if(flv->keyframes.keyframetimestamps != NULL)
		free(flv->keyframes.keyframetimestamps);

	bufferFree(&flv->onmetadata);
	bufferFree(&flv->onlastsecond);
	bufferFree(&flv->onlastkeyframe);
	memset(flv, 0, sizeof(FLV_t));

	return YAMDI_OK;
}

int analyzeFLV(FLV_t *flv, FILE *fp) {
	int rv = YAMDI_OK;
	size_t i, index;
	unsigned char flags;
	FLVTag_t *flvtag;

	for(i = 0; i < flv->index.nflvtags; i++) {
		flvtag = &flv->index.flvtag[i];

		if(flvtag->tagtype == FLV_TAG_AUDIO) {
			flv->hasaudio = 1;

			flv->audio.ntags++;
			flv->audio.datasize += flvtag->datasize;
			flv->audio.size += flvtag->tagsize;

			flv->audio.lasttimestamp = flvtag->timestamp;
			flv->audio.lastframeindex = i;

			readFLVTagData(&flags, 1, flvtag, fp);

			if(flv->audio.analyzed == 0) {
				// SoundFormat
				flv->audio.codecid = (flags >> 4) & 0xf;

				// SoundRate
				flv->audio.samplerate = (flags >> 2) & 0x3;

				// SoundSize
				flv->audio.samplesize = (flags >> 1) & 0x1;

				// SoundType
				flv->audio.stereo = flags & 0x1;

				if(flv->audio.codecid == 4 || flv->audio.codecid == 5 || flv->audio.codecid == 6) {
					// Nellymoser
					flv->audio.stereo = 0;
				}
				else if(flv->audio.codecid == 10) {
					// AAC
					flv->audio.samplerate = 3;
					flv->audio.stereo = 1;
				}

				flv->audio.analyzed = 1;
			}
		}
		else if(flvtag->tagtype == FLV_TAG_VIDEO) {
			flv->hasvideo = 1;

			flv->video.ntags++;
			flv->video.datasize += flvtag->datasize;
			flv->video.size += flvtag->tagsize;

			flv->video.lasttimestamp = flvtag->timestamp;
			flv->video.lastframeindex = i;

			readFLVTagData(&flags, 1, flvtag, fp);

			// Keyframes
			flvtag->keyframe = (flags >> 4) & 0xf;
			if(flvtag->keyframe == 1) {
				flv->canseektoend = 1;
				flv->keyframes.nkeyframes++;
				flv->keyframes.lastkeyframeindex = i;
			}
			else
				flv->canseektoend = 0;

			if(flvtag->keyframe == 1 && flv->video.analyzed == 0) {
				// Video Codec
				flv->video.codecid = flags & 0xf;

				//switch(flv->video.codecid) {
				//	case FLV_PACKET_H263VIDEO:
				//		rv = analyzeFLVH263VideoPacket(flv, flvtag, fp);
				//		break;
				//	case FLV_PACKET_SCREENVIDEO:
				//		rv = analyzeFLVScreenVideoPacket(flv, flvtag, fp);
				//		break;
				//	case FLV_PACKET_VP6VIDEO:
				//		rv = analyzeFLVVP6VideoPacket(flv, flvtag, fp);
				//		break;
				//	case FLV_PACKET_VP6ALPHAVIDEO:
				//		rv = analyzeFLVVP6AlphaVideoPacket(flv, flvtag, fp);
				//		break;
				//	case FLV_PACKET_SCREENV2VIDEO:
				//		rv = analyzeFLVScreenVideoPacket(flv, flvtag, fp);
				//		break;
				//	case FLV_PACKET_H264VIDEO:
				//		rv = analyzeFLVH264VideoPacket(flv, flvtag, fp);
				//		break;
				//	default:
				//		rv = YAMDI_ERROR;
				//		break;
				//}

				if(rv == YAMDI_OK)
					flv->video.analyzed = 1;
			}
		}

		flv->lasttimestamp = flvtag->timestamp;
	}

	// Calculate the last second
	if(flv->lasttimestamp >= 1000) {
		flv->lastsecond = flv->lasttimestamp - 1000;
		for(i = (flv->index.nflvtags - 1); i >= 0; i--) {
			flvtag = &flv->index.flvtag[i];

			if(flvtag->timestamp <= flv->lastsecond) {
				flv->lastsecond += 1;
				flv->lastsecondindex = i;
				break;
			}
		}
	}

	// Calculate audio datarate
	if(flv->audio.datasize != 0)
		flv->audio.datarate = (double)flv->audio.datasize * 8.0 / 1024.0 / (double)flv->audio.lasttimestamp * 1000.0;

	// Calculate video framerate
	if(flv->video.ntags != 0)
		flv->video.framerate = (double)flv->video.ntags / (double)flv->video.lasttimestamp * 1000.0;

	// Calculate video datarate
	if(flv->video.datasize != 0)
		flv->video.datarate = (double)flv->video.datasize * 8.0 / 1024.0 / (double)flv->lasttimestamp * 1000.0;

	// Calculate datasize
	flv->datasize = flv->audio.size + (flv->audio.ntags * FLV_SIZE_PREVIOUSTAGSIZE) + flv->video.size + (flv->video.ntags * FLV_SIZE_PREVIOUSTAGSIZE);

	// Allocate some memory for the keyframe index
	if(flv->keyframes.nkeyframes != 0) {
		flv->haskeyframes = 1;

		flv->keyframes.keyframelocations = (__int64 *)calloc(flv->keyframes.nkeyframes, sizeof(__int64));
		if(flv->keyframes.keyframelocations == NULL)
			return YAMDI_OUT_OF_MEMORY;

		flv->keyframes.keyframetimestamps = (int *)calloc(flv->keyframes.nkeyframes, sizeof(int));
		if(flv->keyframes.keyframetimestamps == NULL)
			return YAMDI_OUT_OF_MEMORY;
	}

	return YAMDI_OK;
}

int finalizeFLV(FLV_t *flv, FILE *fp) {
	size_t i, index;
	FLVTag_t *flvtag;

	// 2 passes
	// 1. create onmetadata event to get the size of it (it doesn't matter if the values are not yet correct)
	// 2. calculate the new keyframelocations and the final filesize
	//    pay attention to the size of these events
	//        onmetadata
	//        onlastsecond
	//        onlastkeyframe
	//        (oncuepoint) keep them from the input flv?
	// 3. recreate the onmetadata event with the correct values
	// filesize
	// keyframelocations
	// lastkeyframelocation

	// Create the metadata tags. Even though we don't have all values,
	// the size will not change. We need the size.
	if(flv->options.addonmetadata == 1)
		createFLVEventOnMetaData(flv);

	// Start calculating the final filesize
	flv->filesize = 0;

	// FLV header + PreviousTagSize
	flv->filesize += FLV_SIZE_HEADER + FLV_SIZE_PREVIOUSTAGSIZE;

	// onMetaData event
	if(flv->options.addonmetadata == 1)
		flv->filesize += flv->onmetadata.used;

	// Calculate the final filesize and update the keyframe index
	index = 0;
	for(i = 0; i < flv->index.nflvtags; i++) {
		flvtag = &flv->index.flvtag[i];

		// Skip every script tag (subject to change if we want to keep existing events)
		if(flvtag->tagtype != FLV_TAG_AUDIO && flvtag->tagtype != FLV_TAG_VIDEO)
			continue;

		// Update the keyframe index only if there are keyframes ...
		if(flv->haskeyframes == 1) {
			if(flvtag->tagtype == FLV_TAG_VIDEO || flvtag->tagtype == FLV_TAG_AUDIO) {
				// Keyframes
				if(flvtag->keyframe == 1) {

					flv->keyframes.keyframelocations[index] = flv->filesize;
					flv->keyframes.keyframetimestamps[index] = flvtag->timestamp;

					index++;
				}
			}
		}

		flv->filesize += flvtag->tagsize + FLV_SIZE_PREVIOUSTAGSIZE;
	}

	if(flv->haskeyframes == 1) {
		flv->keyframes.lastkeyframetimestamp = flv->keyframes.keyframetimestamps[flv->keyframes.nkeyframes - 1];
		flv->keyframes.lastkeyframelocation = flv->keyframes.keyframelocations[flv->keyframes.nkeyframes - 1];
	}

	// Create the metadata tags with the correct values
	if(flv->options.addonmetadata == 1)
		createFLVEventOnMetaData(flv);

	return YAMDI_OK;
}

void initCipherCode(FLV_t *flv, const  char *cipherkeybuf)
{
	int cipherkey = time(NULL);
	int cipherkey_len = strlen(cipherkeybuf);

	for (int i = 0; i < cipherkey_len; ++i)
		cipherkey += ((cipherkeybuf[i] << (i & 0xFF) ) ^ 0xFF);

	if (cipherkey_len > 0)
	{
		flv->hascipherkey = 1;
		flv->cipherkey = cipherkey;
	}
}

void encryptionFLV(unsigned char *buf, int len, int key) {
	for (int i = 0; i < len; ++i) {
		buf[i] ^= key;
	}
}

int writeFLV(FILE *out, FLV_t *flv, FILE *fp) {
	size_t i, datasize = 0;
	unsigned char *data = NULL, *d;
	FLVTag_t *flvtag;

	if(fp == NULL)
		return YAMDI_ERROR;

	// Write the header
	writeFLVHeader(out, flv->hasaudio, flv->hasvideo);
	writeFLVPreviousTagSize(out, flv->onmetadata.used, false, flv);

	// Write the onMetaData tag
	if(flv->options.addonmetadata == 1)
	{
		if (flv->hascipherkey) {
			encryptionFLV(flv->onmetadata.data, flv->onmetadata.used, 0x7F);
		}
		fwrite(flv->onmetadata.data, flv->onmetadata.used, 1, out);
	}

	// Copy the audio and video tags
	for(i = 0; i < flv->index.nflvtags; i++) {
		flvtag = &flv->index.flvtag[i];

		// Skip every script tag (subject to change if we want to keep existing events)
		if(flvtag->tagtype != FLV_TAG_AUDIO && flvtag->tagtype != FLV_TAG_VIDEO)
			continue;

		writeFLVDataTag(out, flvtag->tagtype, flvtag->timestamp, flvtag->datasize, flv);

		// Read the data
		if(flvtag->datasize > datasize) {
			d = (unsigned char *)realloc(data, flvtag->datasize);
			if(d == NULL)
				return YAMDI_OUT_OF_MEMORY;

			data = d;
			datasize = flvtag->datasize;
		}

		if(readFLVTagData(data, flvtag->datasize, flvtag, fp) != YAMDI_OK)
			return YAMDI_READ_ERROR;

		if (flv->hascipherkey) {
			encryptionFLV(data, flvtag->datasize, flv->cipherkey);
		}
		fwrite(data, flvtag->datasize, 1, out);

		writeFLVPreviousTagSize(out, flvtag->tagsize, true, flv);
	}

	if(data != NULL)
		free(data);

	// We are done!

	return YAMDI_OK;
}

int writeFLVHeader(FILE *fp, int hasaudio, int hasvideo) {
	unsigned char bytes[FLV_SIZE_HEADER];

	// Signature
	bytes[0] = 'C';
	bytes[1] = 'K';
	bytes[2] = 'F';

	// Version
	bytes[3] = 1;

	// Flags
	bytes[4] = 0;

	if(hasaudio == 1)
		bytes[4] |= 0x4;

	if(hasvideo == 1)
		bytes[4] |= 0x1;

	// DataOffset
	bytes[5] = ((FLV_SIZE_HEADER >> 24) & 0xff);
	bytes[6] = ((FLV_SIZE_HEADER >> 16) & 0xff);
	bytes[7] = ((FLV_SIZE_HEADER >>  8) & 0xff);
	bytes[8] = ((FLV_SIZE_HEADER >>  0) & 0xff);

	fwrite(bytes, FLV_SIZE_HEADER, 1, fp);

	return YAMDI_OK;
}


int createFLVEventOnMetaData(FLV_t *flv) {
	int pass = 0;
	size_t i, length = 0;
	buffer_t b;

	bufferInit(&b);

onmetadatapass:
	bufferReset(&b);

	// ScriptDataObject
	writeBufferFLVScriptDataObject(&b);

	writeBufferFLVScriptDataECMAArray(&b, "onMetaData", length);

	length = 0;

	if(strlen(flv->options.creator) != 0) {
		writeBufferFLVScriptDataValueString(&b, "creator", flv->options.creator); length++;
	}

	writeBufferFLVScriptDataValueString(&b, "metadatacreator", "Yet Another Metadata Injector for FLV - Version " YAMDI_VERSION "\0"); length++;
	writeBufferFLVScriptDataValueBool(&b, "hasKeyframes", flv->haskeyframes); length++;
	writeBufferFLVScriptDataValueBool(&b, "hasVideo", flv->hasvideo); length++;
	writeBufferFLVScriptDataValueBool(&b, "hasAudio", flv->hasaudio); length++;
	writeBufferFLVScriptDataValueBool(&b, "hasMetadata", 1); length++;
	writeBufferFLVScriptDataValueBool(&b, "canSeekToEnd", flv->canseektoend); length++;

	writeBufferFLVScriptDataValueDouble(&b, "duration", (double)flv->lasttimestamp / 1000.0); length++;
	writeBufferFLVScriptDataValueDouble(&b, "datasize", (double)flv->datasize); length++;

	if(flv->hasvideo == 1) {
		writeBufferFLVScriptDataValueDouble(&b, "videosize", (double)flv->video.size); length++;
		writeBufferFLVScriptDataValueDouble(&b, "framerate", (double)flv->video.framerate); length++;
		writeBufferFLVScriptDataValueDouble(&b, "videodatarate", (double)flv->video.datarate); length++;

		//if(flv->video.analyzed == 1) {
		//	writeBufferFLVScriptDataValueDouble(&b, "videocodecid", (double)flv->video.codecid); length++;
		//	writeBufferFLVScriptDataValueDouble(&b, "width", (double)flv->video.width); length++;
		//	writeBufferFLVScriptDataValueDouble(&b, "height", (double)flv->video.height); length++;
		//}
	}

	if(flv->hasaudio == 1) {
		writeBufferFLVScriptDataValueDouble(&b, "audiosize", (double)flv->audio.size); length++;
		writeBufferFLVScriptDataValueDouble(&b, "audiodatarate", (double)flv->audio.datarate); length++;

		if(flv->audio.analyzed == 1) {
			writeBufferFLVScriptDataValueDouble(&b, "audiocodecid", (double)flv->audio.codecid); length++;
			writeBufferFLVScriptDataValueDouble(&b, "audiosamplerate", (double)flv->audio.samplerate); length++;
			writeBufferFLVScriptDataValueDouble(&b, "audiosamplesize", (double)flv->audio.samplesize); length++;
			writeBufferFLVScriptDataValueBool(&b, "stereo", flv->audio.stereo); length++;
		}
	}

	if (flv->hascipherkey) {
		writeBufferFLVScriptDataValueDouble(&b, "cipherkey", (double)flv->cipherkey); length++;
	}

	writeBufferFLVScriptDataValueDouble(&b, "filesize", (double)flv->filesize); length++;
	writeBufferFLVScriptDataValueDouble(&b, "lasttimestamp", (double)flv->lasttimestamp / 1000.0); length++;

	if(flv->haskeyframes == 1) {
		writeBufferFLVScriptDataValueDouble(&b, "lastkeyframetimestamp", (double)flv->keyframes.lastkeyframetimestamp / 1000.0); length++;
		writeBufferFLVScriptDataValueDouble(&b, "lastkeyframelocation", (double)flv->keyframes.lastkeyframelocation); length++;

		writeBufferFLVScriptDataVariableArray(&b, "keyframes"); length++;

			writeBufferFLVScriptDataValueArray(&b, "filepositions", flv->keyframes.nkeyframes);

			for(i = 0; i < flv->keyframes.nkeyframes; i++)
				writeBufferFLVScriptDataValueDouble(&b, NULL, (double)flv->keyframes.keyframelocations[i]);

			writeBufferFLVScriptDataValueArray(&b, "times", flv->keyframes.nkeyframes);

			for(i = 0; i < flv->keyframes.nkeyframes; i++)
				writeBufferFLVScriptDataValueDouble(&b, NULL, (double)flv->keyframes.keyframetimestamps[i] / 1000.0);

		writeBufferFLVScriptDataVariableArrayEnd(&b);
	}

	writeBufferFLVScriptDataVariableArrayEnd(&b);

	if(pass == 0) {
		pass = 1;
		goto onmetadatapass;
	}

	// Write the onMetaData tag
	bufferReset(&flv->onmetadata);

	writeBufferFLVScriptDataTag(&flv->onmetadata, 0, b.used);
	bufferAppendBuffer(&flv->onmetadata, &b);
	writeBufferFLVPreviousTagSize(&flv->onmetadata, flv->onmetadata.used);

	bufferFree(&b);

	return YAMDI_OK;
}

int writeBufferFLVScriptDataTag(buffer_t *buffer, int timestamp, size_t datasize) {
	unsigned char bytes[FLV_SIZE_TAGHEADER];

	bytes[ 0] = FLV_TAG_SCRIPTDATA;

	// DataSize
	bytes[ 1] = ((datasize >> 16) & 0xff);
	bytes[ 2] = ((datasize >>  8) & 0xff);
	bytes[ 3] = ((datasize >>  0) & 0xff);

	// Timestamp
	bytes[ 4] = ((timestamp >> 16) & 0xff);
	bytes[ 5] = ((timestamp >>  8) & 0xff);
	bytes[ 6] = ((timestamp >>  0) & 0xff);

	// TimestampExtended
	bytes[ 7] = ((timestamp >> 24) & 0xff);

	// StreamID
	bytes[ 8] = 0;
	bytes[ 9] = 0;
	bytes[10] = 0;

	bufferAppendBytes(buffer, bytes, FLV_SIZE_TAGHEADER);

	return YAMDI_OK;
}

int writeFLVDataTag(FILE *fp, int type, int timestamp, size_t datasize, FLV_t *flv) {
	unsigned char bytes[FLV_SIZE_TAGHEADER];

	bytes[ 0] = type;

	// DataSize
	bytes[ 1] = ((datasize >> 16) & 0xff);
	bytes[ 2] = ((datasize >>  8) & 0xff);
	bytes[ 3] = ((datasize >>  0) & 0xff);

	// Timestamp
	bytes[ 4] = ((timestamp >> 16) & 0xff);
	bytes[ 5] = ((timestamp >>  8) & 0xff);
	bytes[ 6] = ((timestamp >>  0) & 0xff);

	// TimestampExtended
	bytes[ 7] = ((timestamp >> 24) & 0xff);

	// StreamID
	bytes[ 8] = 0;
	bytes[ 9] = 0;
	bytes[10] = 0;

	if (flv->hascipherkey) {
		encryptionFLV(bytes, FLV_SIZE_TAGHEADER, flv->cipherkey);
	}
	fwrite(bytes, FLV_SIZE_TAGHEADER, 1, fp);

	return YAMDI_OK;
}

int writeBufferFLVPreviousTagSize(buffer_t *buffer, size_t tagsize) {
	unsigned char bytes[4];

	bytes[0] = ((tagsize >> 24) & 0xff);
	bytes[1] = ((tagsize >> 16) & 0xff);
	bytes[2] = ((tagsize >>  8) & 0xff);
	bytes[3] = ((tagsize >>  0) & 0xff);

	bufferAppendBytes(buffer, bytes, 4);

	return YAMDI_OK;
}

int writeFLVPreviousTagSize(FILE *fp, size_t tagsize, bool encry, FLV_t *flv) {
	unsigned char bytes[4];

	bytes[0] = ((tagsize >> 24) & 0xff);
	bytes[1] = ((tagsize >> 16) & 0xff);
	bytes[2] = ((tagsize >>  8) & 0xff);
	bytes[3] = ((tagsize >>  0) & 0xff);

	if (encry && flv->hascipherkey) {
		encryptionFLV(bytes, 4, flv->cipherkey);
	}
	fwrite(bytes, 4, 1, fp);

	return YAMDI_OK;
}

int writeBufferFLVScriptDataObject(buffer_t *buffer) {
	unsigned char type = 2;

	bufferAppendBytes(buffer, &type, 1);

	return YAMDI_OK;
}

int writeBufferFLVScriptDataECMAArray(buffer_t *buffer, const char *name, size_t len) {
	unsigned char type, bytes[4];

	writeBufferFLVScriptDataString(buffer, name);

	type = 8;	// ECMAArray
	bufferAppendBytes(buffer, &type, 1);

	bytes[0] = ((len >> 24) & 0xff);
	bytes[1] = ((len >> 16) & 0xff);
	bytes[2] = ((len >>  8) & 0xff);
	bytes[3] = ((len >>  0) & 0xff);

	bufferAppendBytes(buffer, bytes, 4);

	return YAMDI_OK;
}

int writeBufferFLVScriptDataValueArray(buffer_t *buffer, const char *name, size_t len) {
	unsigned char type, bytes[4];
	
	writeBufferFLVScriptDataString(buffer, name);

	type = 10;	// Value Array
	bufferAppendBytes(buffer, &type, 1);

	bytes[0] = ((len >> 24) & 0xff);
	bytes[1] = ((len >> 16) & 0xff);
	bytes[2] = ((len >>  8) & 0xff);
	bytes[3] = ((len >>  0) & 0xff);

	bufferAppendBytes(buffer, bytes, 4);

	return YAMDI_OK;
}

int writeBufferFLVScriptDataVariableArray(buffer_t *buffer, const char *name) {
	unsigned char type;

	writeBufferFLVScriptDataString(buffer, name);

	type = 3;	// Variable Array
	bufferAppendBytes(buffer, &type, 1);

	return YAMDI_OK;
}

int writeBufferFLVScriptDataVariableArrayEnd(buffer_t *buffer) {
	unsigned char bytes[3];

	bytes[0] = 0;
	bytes[1] = 0;
	bytes[2] = 9;

	bufferAppendBytes(buffer, bytes, 3);

	return YAMDI_OK;
}

int writeBufferFLVScriptDataValueString(buffer_t *buffer, const char *name, const char *value) {
	unsigned char type;

	if(name != NULL)
		writeBufferFLVScriptDataString(buffer, name);

	type = 2;	// DataString	
	bufferAppendBytes(buffer, &type, 1);

	writeBufferFLVScriptDataString(buffer, value);

	return YAMDI_OK;
}

int writeBufferFLVScriptDataValueBool(buffer_t *buffer, const char *name, int value) {
	unsigned char type;

	if(name != NULL)
		writeBufferFLVScriptDataString(buffer, name);

	type = 1;	// Bool
	bufferAppendBytes(buffer, &type, 1);

	writeBufferFLVBool(buffer, value);

	return YAMDI_OK;
}

int writeBufferFLVScriptDataValueDouble(buffer_t *buffer, const char *name, double value) {
	unsigned char type;

	if(name != NULL)
		writeBufferFLVScriptDataString(buffer, name);

	type = 0;	// Double
	bufferAppendBytes(buffer, &type, 1);

	writeBufferFLVDouble(buffer, value);

	return YAMDI_OK;
}

int writeBufferFLVScriptDataString(buffer_t *buffer, const char *s) {
	size_t len;
	unsigned char bytes[2];

	len = strlen(s);

	// critical, if only DataString is expected?
	if(len > 0xffff)
		writeBufferFLVScriptDataLongString(buffer, s);
	else {
		bytes[0] = ((len >> 8) & 0xff);
		bytes[1] = ((len >> 0) & 0xff);

		bufferAppendBytes(buffer, bytes, 2);
		bufferAppendString(buffer, (unsigned char*)s);
	}

	return YAMDI_OK;
}

int writeBufferFLVScriptDataLongString(buffer_t *buffer, const char *s) {
	size_t len;
	unsigned char bytes[4];

	len = strlen(s);

	if(len > 0xffffffff)
		len = 0xffffffff;

	bytes[0] = ((len >> 24) & 0xff);
	bytes[1] = ((len >> 16) & 0xff);
	bytes[2] = ((len >>  8) & 0xff);
	bytes[3] = ((len >>  0) & 0xff);

	bufferAppendBytes(buffer, bytes, 4);
	bufferAppendString(buffer, (unsigned char *)s);

	return YAMDI_OK;
}

int writeBufferFLVBool(buffer_t *buffer, int value) {
	unsigned char b;

	b = (value & 1);

	bufferAppendBytes(buffer, &b, 1);

	return YAMDI_OK;
}

int writeBufferFLVDouble(buffer_t *buffer, double value) {
	union {
		unsigned char dc[8];
		double dd;
	} d;
	unsigned char b[8];

	d.dd = value;

	if(isBigEndian()) {
		b[0] = d.dc[0];
		b[1] = d.dc[1];
		b[2] = d.dc[2];
		b[3] = d.dc[3];
		b[4] = d.dc[4];
		b[5] = d.dc[5];
		b[6] = d.dc[6];
		b[7] = d.dc[7];
	}
	else {
		b[0] = d.dc[7];
		b[1] = d.dc[6];
		b[2] = d.dc[5];
		b[3] = d.dc[4];
		b[4] = d.dc[3];
		b[5] = d.dc[2];
		b[6] = d.dc[1];
		b[7] = d.dc[0];
	}

	bufferAppendBytes(buffer, b, 8);

	return YAMDI_OK;
}

int readFLVTag(FLVTag_t *flvtag, __int64 offset, FILE *fp) {
	int rv;
	unsigned char buffer[FLV_SIZE_TAGHEADER];

	memset(flvtag, 0, sizeof(FLVTag_t));

	rv = _fseeki64(fp, offset, SEEK_SET);
	if(rv != 0) {
		return YAMDI_READ_ERROR;
	}

	flvtag->offset = offset;

	// Read the header
	if(readBytes(buffer, FLV_SIZE_TAGHEADER, fp) != YAMDI_OK)
		return YAMDI_READ_ERROR;

	flvtag->tagtype = FLV_UI8(buffer);

	// Assuming only known tags. Otherwise we only process the
	// input file up to this point. It is not possible to detect
	// where the next valid tag could be.
	switch(flvtag->tagtype) {
		case FLV_TAG_VIDEO:
		case FLV_TAG_AUDIO:
		case FLV_TAG_SCRIPTDATA:
			break;
		default:
			return YAMDI_INVALID_TAGTYPE;
	}

	flvtag->datasize = (size_t)FLV_UI24(&buffer[1]);
	flvtag->timestamp = FLV_TIMESTAMP(&buffer[4]);

	// Skip the data
	readBytes(NULL, flvtag->datasize, fp);

	// Read the previous tag size
	readBytes(buffer, FLV_SIZE_PREVIOUSTAGSIZE, fp);

	flvtag->tagsize = FLV_SIZE_TAGHEADER + flvtag->datasize;

	return YAMDI_OK;
}

int readFLVTagData(unsigned char *ptr, size_t size, FLVTag_t *flvtag, FILE *stream) {
	// check for size <= flvtag->datasize?

	_fseeki64(stream, flvtag->offset + FLV_SIZE_TAGHEADER, SEEK_SET);

	return readBytes(ptr, size, stream);
}

int readBytes(unsigned char *ptr, size_t size, FILE *stream) {
	size_t bytesread;

	if(ptr == NULL) {
		_fseeki64(stream, size, SEEK_CUR);
		return YAMDI_OK;
	}

	bytesread = fread(ptr, 1, size, stream);
	if(bytesread < size)
		return YAMDI_READ_ERROR;

	return YAMDI_OK;
}


int readBits(bitstream_t *bitstream, int nbits) {
	int i, rv = 0;

	for(i = 0; i < nbits; i++) {
		rv = (rv << 1);
		rv += readBit(bitstream);
	}

	return rv;
}

int readBit(bitstream_t *bitstream) {
	int bit;

	if(bitstream->byte == bitstream->length)
		return 0;

	bit = (bitstream->bytes[bitstream->byte] >> (7 - bitstream->bit)) & 0x01;

	bitstream->bit++;
	if(bitstream->bit == 8) {
		bitstream->byte++;
		bitstream->bit = 0;
	}

	return bit;
}

int bufferInit(buffer_t *buffer) {
	if(buffer == NULL)
		return YAMDI_ERROR;

	buffer->data = NULL;
	buffer->size = 0;
	buffer->used = 0;

	return YAMDI_OK;
}

int bufferFree(buffer_t *buffer) {
	if(buffer == NULL)
		return YAMDI_ERROR;

	if(buffer->data != NULL) {
		free(buffer->data);
		buffer->data = NULL;
	}

	return YAMDI_OK;
}

int bufferReset(buffer_t *buffer) {
	if(buffer == NULL)
		return YAMDI_ERROR;

	buffer->used = 0;

	return YAMDI_OK;
}

int bufferAppendString(buffer_t *dst, const unsigned char *string) {
	if(string == NULL)
		return YAMDI_OK;

	return bufferAppendBytes(dst, string, strlen((char *)string));
}

int bufferAppendBuffer(buffer_t *dst, buffer_t *src) {
	if(src == NULL)
		return YAMDI_OK;

	return bufferAppendBytes(dst, src->data, src->used);
}

int bufferAppendBytes(buffer_t *dst, const unsigned char *bytes, size_t nbytes) {
	size_t size;
	unsigned char *data;

	if(dst == NULL)
		return YAMDI_ERROR;

	if(bytes == NULL)
		return YAMDI_OK;

	if(nbytes == 0)
		return YAMDI_OK;

	// Check if we have to increase the buffer size
	if(dst->size < dst->used + nbytes) {
		// Pre-allocating some memory. Round up to the next 1024 bound
		size = ((dst->used + nbytes) / 1024 + 1) * 1024;

		data = (unsigned char *)realloc(dst->data, size);
		if(data == NULL)
			return YAMDI_ERROR;

		dst->data = data;
		dst->size = size;
	}

	// Copy the stuff into the buffer
	memcpy(&dst->data[dst->used], bytes, nbytes);

	dst->used += nbytes;

	return YAMDI_OK;
}

int isBigEndian(void) {
	long one = 1;
	return !(*((char *)(&one)));
}

void printUsage(void) {
	fprintf(stderr, "NAME\n");
	fprintf(stderr, "\tyamdi -- Yet Another Metadata Injector for FLV\n");
	fprintf(stderr, "\tVersion: " YAMDI_VERSION "\n");
	fprintf(stderr, "\n");

	fprintf(stderr, "SYNOPSIS\n");
	fprintf(stderr, "\tyamdi -i input file [-x xml file | -o output file]\n");
	fprintf(stderr, "\n");

	fprintf(stderr, "DESCRIPTION\n");
	fprintf(stderr, "\tyamdi is a metadata injector for FLV files.\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "\tOptions:\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "\t-i\tThe source FLV file. If the file name is '-' the input\n");
	fprintf(stderr, "\t\tfile will be read from stdin. Use the -t option to specify\n");
	fprintf(stderr, "\t\ta temporary file.\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "\t-o\tThe resulting FLV file with the metatags. If the file\n");
	fprintf(stderr, "\t\tname is '-' the output will be written to stdout.\n");
	fprintf(stderr, "\n");
	fprintf(stderr, "\t-h\tThis description.\n");
	fprintf(stderr, "\n");
	return;
}
