package org.flowplayer.pseudostreaming
{
    import flash.net.NetStream;
    import flash.net.NetStreamAppendBytesAction;
    import flash.net.URLStream;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import org.flowplayer.util.Log;
    
    public class Decipher
    {
        private static const S_START:int = 0;        //略过
        private static const S_PASS:int = 1;        //略过
        private static const S_UNLOCK:int = 2;
        private static const S_SIGN:int = 3;
        private static const S_FILE_HEADER:int = 4;
        private static const S_METADATA_SIZE:int = 5;
        private static const S_METADATA_TAG_HEADER:int = 6;
        private static const S_METADATA_TAG_BODY:int = 7;
        private static const S_METADATA_PRE_TAG_SIZE:int = 8;
        private static const S_GAIN_SECRET_KEY:int = 9;
        private static const S_REMNANTS:int = 10;
        
        private static const FLV_SIZE_HEADER:int = 9;
        private static const FLV_SIZE_PREVIOUSTAGSIZE:int = 4;
        private static const FLV_SIZE_TAGHEADER:int = 11;
        
        private static const FLV_TAG_VIDEO:int = 9;
        private static const FLV_TAG_AUDIO:int = 8;
        private static const FLV_TAG_SCRIPTDATA:int = 18;
        
        private static const FLV_META_TYPE_DOUBLE:int = 0;
        private static const FLV_META_TYPE_BOOLEAN:int = 1;
        private static const FLV_META_TYPE_STRING:int = 2;     
        private static const FLV_META_TYPE_ARRAY:int = 3;     
        private static const FLV_META_TYPE_ARRAY_VALUE:int = 10;
        private static const FLV_META_TYPE_ARRAY_END:int = 9;
        
        private static const FLV_META_DATA_SGLN:String = "onMetaData";
        private static const FLV_META_DATA_CIPHER_KEY:String = "cipherkey";
        
        private static const FLV_META_DATA_TAG_CIPHER_KEY:int = 0x7F;
        
        private var log:Log = new Log(this);
        private var _state:int = S_START;
        private var _secretKey:int = 0;
        
        private var _netStream:NetStream;
        
        private var _metaInfo:Object;
        private var _metaDataSize:int = 0;
        
        private var _bufferPos:uint = 0;
        private var _dataBuffer:ByteArray = new ByteArray();
        
        public function Decipher(netStream:NetStream) {
            _netStream = netStream;
        }
        
        private function Decryption(data:ByteArray, beginPos:uint, endPos:uint):ByteArray {
            for (var i:int = beginPos; i < endPos; ++i) {
                data[i] ^= _secretKey;
            }
            return data;
        }
        
        private function analySign(data:ByteArray):Boolean {
            // Check the FLV signature
            return data[0] == '67' && data[1] == '75' && data[2] == '70';
        }
        
        private function recoverSign(data:ByteArray):void {
            data[0] = '70'; data[1] = '76'; data[2] = '86';
        }
        
        private function analyFileHeader():Boolean {
            var flvFileHeader:ByteArray = new ByteArray();
            _dataBuffer.readBytes(flvFileHeader, 0, FLV_SIZE_HEADER);
    
            // Check the FLV version
            var flvVersion:int = flvFileHeader[3];
            return flvVersion == 1;
        }
        
        private function analyMetaDataTagSize():int {
            var tagSize:int = _dataBuffer.readInt();
            return tagSize;
        }
        
        private function analyMetaTagPreviousTagSize():Boolean {
            recoverMetaDataTag(4);
            var preTagSize:int = _dataBuffer.readInt();
            return preTagSize == _metaDataSize + FLV_SIZE_TAGHEADER;
        }
        
        private function recoverMetaDataTag(recoveLen:int) :void {
            var endPosition:int = _dataBuffer.position + recoveLen;
            for (var i:int = _dataBuffer.position; i < endPosition; ++i) {
                _dataBuffer[i] ^= FLV_META_DATA_TAG_CIPHER_KEY;
            }
        }
        
        private function analyMetaDataTagHeader():Boolean {
            recoverMetaDataTag(FLV_SIZE_TAGHEADER);
            
            var metaTagHeader:ByteArray = new ByteArray();
            _dataBuffer.readBytes(metaTagHeader, 0, FLV_SIZE_TAGHEADER);

            if (metaTagHeader[0] != FLV_TAG_SCRIPTDATA)
                return false;
            _metaDataSize = (metaTagHeader[1] << 16) + (metaTagHeader[2] << 8) + metaTagHeader[3]
            
            return _metaDataSize > 0;
        }
        
        private function readMetaInfoName(metaBody:ByteArray):String {
            var metaNameLen:uint = metaBody.readShort();
            if (metaNameLen <= 0)
                return "";
            var metaName:String = metaBody.readUTFBytes(metaNameLen);
            return metaName;
        }
        
        private function isArrayEnd(metaBody:ByteArray):Boolean {
        return metaBody[metaBody.position] == 0 && 
                metaBody[metaBody.position + 1] == 0 && 
                metaBody[metaBody.position + 2]==9
        }
   
        private function getMetaInfoArrayValue(metaBody:ByteArray):Object {
            
            var arrayList:Dictionary = new Dictionary();
            while (true)
            {
                if (isArrayEnd(metaBody))
                    return arrayList;
                
                var arrayNameLen:uint =  metaBody.readShort();
                var arrayName:String = metaBody.readUTFBytes(arrayNameLen);
                if (metaBody.readByte() != FLV_META_TYPE_ARRAY_VALUE)
                    break;
                
                var arrayValueLen:int = metaBody.readInt();
                arrayList[arrayName.toString()] = new Array(arrayValueLen);
                
                for (var i:int = 0; i < arrayValueLen; ++i)
                {
                    arrayList[arrayName.toString()][i] = getMetaInfoValue(metaBody);
                }
            }
            return null;
        }

        private function getMetaInfoValue(metaBody:ByteArray) : Object {
            
            switch (metaBody.readByte())            //data type
            {
                case FLV_META_TYPE_DOUBLE:         // Double
                {
                    return metaBody.readDouble();
                }
                    
                case FLV_META_TYPE_BOOLEAN:         // Bool
                {
                    return metaBody.readByte() != 0;
                }
                    
                case FLV_META_TYPE_STRING:         // DataString
                {
                    var metaValueLen:uint = metaBody.readShort();
                    var metaValueString:String = 
                        metaBody.readUTFBytes(metaValueLen);
                    return metaValueString;
                }
                    
                case FLV_META_TYPE_ARRAY:         // Variable Array
                {
                    return getMetaInfoArrayValue(metaBody);
                }
            }
            return null;
        }

        private function generateMetaDataObject(metaBody:ByteArray, metaInfo:Dictionary): Boolean {
            
            while (metaBody.bytesAvailable)
            {
                if (isArrayEnd(metaBody))
                    break;
                
                var metaName:String = readMetaInfoName(metaBody);
                if (metaName.length == 0)
                    return false;      
 
                metaInfo[metaName.toString()] = getMetaInfoValue(metaBody);
            }
            return true;
        }
        
        private function analyMetaDataTagBody():Boolean {
            
            recoverMetaDataTag(_metaDataSize);
            
            var metaTagBody:ByteArray = new ByteArray();
            _dataBuffer.readBytes(metaTagBody, 0, _metaDataSize);
            
            // ScriptDataObject
            if (metaTagBody.readByte() != 2)
                return false;
            
            var ecma_name_len:uint = metaTagBody.readShort();
            var ecma_name:String = metaTagBody.readUTFBytes(ecma_name_len);
            if (ecma_name != FLV_META_DATA_SGLN)
                return false;
            
            if (metaTagBody.readByte() != 8)
                return false;
            metaTagBody.readInt();

            _metaInfo = new Object();        
            _metaInfo[FLV_META_DATA_SGLN] = new Dictionary();
            return generateMetaDataObject(metaTagBody, _metaInfo[FLV_META_DATA_SGLN]);
        }
        
        private function analyRemnants():Boolean {
            Decryption(_dataBuffer, 
                _dataBuffer.position, _dataBuffer.length);
            _dataBuffer.position = _dataBuffer.length;
            return true;
        }
        
        private function GainSecretKey() : Boolean {
            var secretKey:Object = _metaInfo[FLV_META_DATA_SGLN][FLV_META_DATA_CIPHER_KEY];
            if (secretKey == null)
                return false;
  
            _secretKey = secretKey as int;
            return true;
        }
        
        private function passData(state:uint):ByteArray {
            var data:ByteArray = _dataBuffer;
            _dataBuffer = null; 
            
            data.position = 0;
            _state = state;
            return data;
        }
        
        private function nextState(state:uint):void {
            _bufferPos = _dataBuffer.position;
            _state = state; 
        }
        
        public function Analyse(data:ByteArray):ByteArray {
            if (_state == S_PASS)
                return data;
            
            if (_state == S_UNLOCK) {
                return Decryption(data, 0, data.length);
            }

            if (_state == S_START) {
                if (!analySign(data))
                {
                    _state = S_PASS;
                    throw "NetStream.Play.ErrorFormat";               
                }
                recoverSign(data);
                _state = S_FILE_HEADER;
            }

            _dataBuffer.position = _dataBuffer.length;
            _dataBuffer.writeBytes(data);
            _dataBuffer.position = _bufferPos;
            
            switch (_state)
            {
                case S_FILE_HEADER:
                {
                    if (_dataBuffer.bytesAvailable < FLV_SIZE_HEADER)
                        return null;             
                    
                    if (!analyFileHeader()) {
                        passData(S_PASS); 
                        throw "NetStream.Play.ErrorFormat";                            
                    }
                    nextState(S_METADATA_SIZE);
                }
                case S_METADATA_SIZE:
                {
                    if (_dataBuffer.bytesAvailable < FLV_SIZE_PREVIOUSTAGSIZE)
                        return null;
              
                    if (analyMetaDataTagSize() == 0){
                        passData(S_PASS); 
                        throw "NetStream.Play.ErrorFormat";                    
                    }
                    nextState(S_METADATA_TAG_HEADER); 
                }                       
                case S_METADATA_TAG_HEADER:
                {                       
                    if (_dataBuffer.bytesAvailable < FLV_SIZE_TAGHEADER)
                        return null;
                     
                    if (!analyMetaDataTagHeader()){
                        passData(S_PASS); 
                        throw "NetStream.Play.ErrorFormat";                     
                    }
                    nextState(S_METADATA_TAG_BODY); 
                }      
                case S_METADATA_TAG_BODY:
                {
                    if (_dataBuffer.bytesAvailable < _metaDataSize)
                        return null;
                  
                    if (!analyMetaDataTagBody()){
                        passData(S_PASS); 
                        throw "NetStream.Play.ErrorFormat";                         
                    }
                    nextState(S_METADATA_PRE_TAG_SIZE); 
                } 
                case S_METADATA_PRE_TAG_SIZE:
                {
                    if (_dataBuffer.bytesAvailable < FLV_SIZE_PREVIOUSTAGSIZE)
                        return null;
                    
                    if (!analyMetaTagPreviousTagSize()){
                        passData(S_PASS); 
                        throw "NetStream.Play.ErrorFormat";                         
                    }
                    nextState(S_GAIN_SECRET_KEY);                     
                }
                case S_GAIN_SECRET_KEY:
                {
                    if (!GainSecretKey())
                        return passData(S_PASS);
                    
                    nextState(S_REMNANTS);   
                }
                case S_REMNANTS:
                {
                    if (_dataBuffer.bytesAvailable > 0)
                    {
                        if (!analyRemnants()) {
                            return passData(S_PASS);                           
                        }
                    }
                    return passData(S_UNLOCK);
                }                             
            }               

            return data;
        }
    }
}