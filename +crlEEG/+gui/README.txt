
The overall structure of the crlEEG.gui package is as follows:

+data: Native crlEEG.gui package data types. 
         These datatypes are lightweight reproductions of many of the 
          other datatypes found elsewhere in crlEEG. The GUI package relies
          entirely on these data types, rather than requiring support
          for multiple other
            Many of these will be lightweight reproductions of other datatypes found elsewhere in crlEEG, 

+render: Rendering functions for each of the datatypes in +data.

+interface: Interfaces combine renderers with user interface structures to 
              permit exploration of the data.

+widget: Useful pieces of code for generating standardized UI interfaces.
