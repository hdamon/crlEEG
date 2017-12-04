

### BELOW IS THE PREVIOUS STRUCTURE OF THIS PACKAGE. THIS INFORMATION HAS BEEN SUPERCEDED
The overall structure of the crlEEG.gui package is as follows:

+data: Native crlEEG.gui package data types. 
         These type.datas are lightweight reproductions of many of the 
          other type.datas found elsewhere in crlEEG. The GUI package relies
          entirely on these data types, rather than requiring support
          for multiple other
            Many of these will be lightweight reproductions of other type.datas found elsewhere in crlEEG, 

+render: Rendering functions for each of the type.datas in +data.

+interface: Interfaces combine renderers with user interface structures to 
              permit exploration of the data.

+widget: Useful pieces of code for generating standardized UI interfaces.
