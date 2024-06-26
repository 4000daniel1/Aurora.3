#define ALL (~0) //For convenience.
#define NONE 0

GLOBAL_LIST_INIT(bitflags, list(1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768))

// for /datum/var/datum_flags
#define DF_USE_TAG (1<<0)
#define DF_ISPROCESSING (1<<2)

///Whether /atom/Initialize() has already run for the object
#define INITIALIZED_1 (1<<5)
