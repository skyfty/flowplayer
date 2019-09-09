#ifndef yamdi_h__
#define yamdi_h__

#ifdef __YAMDI_EXPORT_
#define YAMDIF_API extern"C" __declspec(dllexport)
#else
#ifndef __YAMDI_STATIC_LIB
#define YAMDIF_API extern"C" __declspec(dllimport)
#else
#define YAMDIF_API extern"C"
#endif
#endif

#define YAMDI_OK									0
#define YAMDI_ERROR									1
#define YAMDI_FILE_TOO_SMALL						2
#define YAMDI_INVALID_SIGNATURE						3
#define YAMDI_INVALID_FLVVERSION					4
#define YAMDI_INVALID_DATASIZE						5
#define YAMDI_READ_ERROR							6
#define YAMDI_INVALID_PREVIOUSTAGSIZE				7
#define YAMDI_OUT_OF_MEMORY							8
#define YAMDI_H264_USELESS_NALU						9
#define YAMDI_RENAME_OUTPUT							10
#define YAMDI_INVALID_TAGTYPE						11
#define YAMDI_ERROR_INVALID_IN_FILE					12
#define YAMDI_ERROR_INVALID_OUT_FILE				13
#define YAMDI_ERROR_OPEN_OUT_FILE					14
#define YAMDI_ERROR_OPEN_IN_FILE					15

YAMDIF_API int encryption(const char *infile, const  char *outfile, const  char *cipherkey);

#endif // yamdi_h__
