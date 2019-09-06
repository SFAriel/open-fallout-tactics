local ffi = require("ffi")

local zlib = {}

pcall(ffi.cdef, [[
enum {
  Z_NO_FLUSH            = 0,
  Z_PARTIAL_FLUSH       = 1,
  Z_SYNC_FLUSH          = 2,
  Z_FULL_FLUSH          = 3,
  Z_FINISH              = 4,
  Z_BLOCK               = 5,
  Z_TREES               = 6,
  /* Allowed flush values; see deflate() and inflate() below for details */
  Z_OK                  = 0,
  Z_STREAM_END          = 1,
  Z_NEED_DICT           = 2,
  Z_ERRNO               = -1,
  Z_STREAM_ERROR        = -2,
  Z_DATA_ERROR          = -3,
  Z_MEM_ERROR           = -4,
  Z_BUF_ERROR           = -5,
  Z_VERSION_ERROR       = -6,
  /*
   * Return codes for the compression/decompression functions. Negative values
   * are errors, positive values are used for special but normal events.
   */
  Z_NO_COMPRESSION      =  0,
  Z_BEST_SPEED          =  1,
  Z_BEST_COMPRESSION    =  9,
  Z_DEFAULT_COMPRESSION = -1,
  /* compression levels */
  Z_FILTERED            =  1,
  Z_HUFFMAN_ONLY        =  2,
  Z_RLE                 =  3,
  Z_FIXED               =  4,
  Z_DEFAULT_STRATEGY    =  0,
  /* compression strategy; see deflateInit2() below for details */
  Z_BINARY              =  0,
  Z_TEXT                =  1,
  Z_ASCII               =  Z_TEXT, /* for compatibility with 1.2.2 and earlier */
  Z_UNKNOWN             =  2,
  /* Possible values of the data_type field (though see inflate()) */
  Z_DEFLATED            =  8,
  /* The deflate compression method (the only one supported in this version) */
  Z_NULL                =  0,  /* for initializing zalloc, zfree, opaque */
};

typedef void* (* z_alloc_func) ( void* opaque, unsigned items, unsigned size );
typedef void  (* z_free_func)  ( void* opaque, void* address );

typedef struct z_stream_s {
  char*         next_in;
  unsigned      avail_in;
  unsigned long total_in;
  char*         next_out;
  unsigned      avail_out;
  unsigned long total_out;
  char*         msg;
  void*         state;
  z_alloc_func  zalloc;
  z_free_func   zfree;
  void*         opaque;
  int           data_type;
  unsigned long adler;
  unsigned long reserved;
} z_stream;

const char* zlibVersion();
const char* zError(int);

int inflate(z_stream*, int flush);
int inflateEnd(z_stream*);
int inflateInit2_(z_stream*, int windowBits, const char* version, int stream_size);
int uncompress(uint8_t *dest, unsigned long *destLen, const uint8_t *source, unsigned long sourceLen);
]])

local z = ffi.load(ffi.os == "Windows" and (ffi.arch == "x64" and "zlib123_x64" or "zlib123") or "z")

local version = ffi.string(z.zlibVersion())

function zlib.version()
  return version
end

local Z_OK = z.Z_OK
local Z_NO_FLUSH = z.Z_NO_FLUSH
local Z_STREAM_END = z.Z_STREAM_END
local Z_NEED_DICT = z.Z_NEED_DICT
local Z_BUF_ERROR = z.Z_BUF_ERROR

local function translateErrorCode(err)
  return ffi.string(z.zError(err))
end

local ZlibStreamType = ffi.typeof("z_stream")

local function createStream(inputBuffer, outputBuffer)
  local stream = ZlibStreamType()

  stream.next_in = inputBuffer
  stream.avail_in = 0
  stream.next_out = outputBuffer
  stream.avail_out = 0

  return stream
end

local function initInflate(stream, windowBits)
  return z.inflateInit2_(stream, windowBits, version, ffi.sizeof(stream))
end

local function flushOutput(stream, bufferSize, output, outputBuffer)
  local availableOutputBytes = bufferSize - stream.avail_out

  if availableOutputBytes > 0 then
    --output(ffi.string(outputBuffer, availableOutputBytes), availableOutputBytes)
    output(outputBuffer, availableOutputBytes)
  end
end

local function inflateStream(input, output, bufferSize, stream, inputBuffer, outputBuffer)
  local err = 0

  repeat
    local data = input(bufferSize)

    if data then
      ffi.copy(inputBuffer, data)

      stream.next_in = inputBuffer
      stream.avail_in = #data
    else
      stream.avail_in = 0 -- no more input data
    end

    if stream.avail_in == 0 then -- When decompressing we *must* have input bytes
      z.inflateEnd(stream)

      return false, "INFLATE: Data error, no input bytes"
    end

    -- While the output buffer is being filled completely just keep going
    repeat
      stream.next_out  = outputBuffer
      stream.avail_out = bufferSize

      -- Process the stream, always Z_NO_FLUSH in inflate mode
      err = z.inflate(stream, Z_NO_FLUSH)

      if err == Z_BUF_ERROR then -- Buffer errors are OK here
        err = Z_OK
      end

      if err < Z_OK or err == Z_NEED_DICT then
        z.inflateEnd(stream)

        return false, "INFLATE: " .. translateErrorCode(err), stream
      end

      flushOutput(stream, bufferSize, output, outputBuffer)
    until stream.avail_out ~= 0
  until err == Z_STREAM_END

  z.inflateEnd(stream)

  return true
end

local DEFAULT_CHUNK_SIZE = 16384
local DEFAULT_WINDOW_BITS = 15 + 32 -- +32 sets automatic header detection

local VarCharType = ffi.typeof("char[?]")

function zlib.inflate(input, output, bufferSize, windowBits)
  bufferSize = bufferSize or DEFAULT_CHUNK_SIZE
  windowBits = windowBits or DEFAULT_WINDOW_BITS

  local inputBuffer = VarCharType(bufferSize + 1)
  local outputBuffer = VarCharType(bufferSize)
  local stream = createStream(inputBuffer, outputBuffer)
  local initStatus = initInflate(stream, windowBits)

  if initStatus == Z_OK then
    return inflateStream(input, output, bufferSize, stream, inputBuffer, outputBuffer)
  end

  z.inflateEnd(stream)

  return false, "init: " .. translateErrorCode(initStatus)
end

local UnsignedByteArray = ffi.typeof("uint8_t[?]")
local bufferLength = ffi.new("unsigned long[1]")

function zlib.uncompress(byteData, originalLength)
  local buffer = UnsignedByteArray(originalLength)

  bufferLength[0] = originalLength

  local returnCode = z.uncompress(buffer, bufferLength, byteData:getPointer(), byteData:getSize())

  if returnCode ~= Z_OK then
    return false, "uncompress: " .. translateErrorCode(returnCode)
  end

  return buffer, bufferLength[0]
end

return zlib
