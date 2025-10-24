# wls2f90
a program written in Fortran that can transfer Result provided by Mathematica into modern Fortran formmat.

## For Complile
Just download the repository, enter its directory and run 
  $ make
provided gfortran compiler is available. If not, edit the Makefile, and replace gfortran with the one you use. after complie, a executable named "wls2f90" will be generated. It may be convienient to create a symbolic link to this executable in your system's PATH.

## Usage
transfer single file

  $ wls2f90 wls.txt fortran.f90
  
transfer multiple files specified in "wls_file_list.txt", and create a file named "f90_file_list.f90" to be include to your Fortran program

  $ wls2f90 -m wls_file_list.txt f90_file_list.f90
  
Then in your Fortran program, you can just "#include "f90_file_list.f90"

## License

Copyright (C) <2025>  Han Zhang

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
