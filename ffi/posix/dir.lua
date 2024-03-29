local ffi = require("ffi")

ffi.cdef [[
  struct dirent {
    unsigned long  d_ino;       /* inode number */
    unsigned long  d_off;       /* not an offset */
    unsigned short d_reclen;    /* length of this record */
    unsigned char  d_type;      /* type of file; not supported by all filesystem types */
    char           d_name[256]; /* filename */
  };

  struct DIR *opendir(const char *name);
  struct dirent *readdir(struct DIR *dirstream);
  int closedir (struct DIR *dirstream);
]]

local dir = {}

function dir.list(absolutePath)
  error("not implemented")
end

return dir
