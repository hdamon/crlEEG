# crlEEG : 

An object oriented Matlab package for reading, viewing, marking, and processing electroencephalography (EEG) signals

crlEEG is an M/EEG specific extension of the MatTSA package for timeseries analysis (https://github.com/hdamon/MatTSA), which is itself a specific implementation of the labelledArray package (https://github.com/hdaemon/labelledArray). The basic philosophy is that labelledArray provides the underlying functionality for operating on multi-dimensional arrays whose dimensions have intrinsic named or valued associations. MatTSA is one such implementation, and provides the MatTSA.timeseries and MatTSA.tfDecomp (time-frequency decomposition) classes,

## INSTALLATION:
The crlEEG library is dependant on the follow two external libraries:
- MatTSA (https://github.com/hdamon/MatTSA)   : Provides timeseries and time-frequency decomposition functionality.
- labelledArray : https://github.com/hdamon/) : Provides the basic data structure underlying the crlEEG.EEG, MatTSA.timeseries, and 
- crlBase : https://github.com/hdamon/crlBase : Provides certain basic functionality the is reused across multiple packages. May soon be incorporated as a proper submodule.

## INTRODUCTION:
The primary function of the crlEEG package is to provide an EEG specific implementation of a MatTSA.timeseries object, as well as file I/O for a range of common M/EEG filetypes.




