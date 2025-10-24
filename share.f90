module share
    implicit none (type, external)
    private
    integer, public, parameter :: char_string_length = 256
    character(len=*), public, parameter :: fortran_extension = '.f90'
    integer, public, parameter :: unit1 = 11
    integer, public, parameter :: unit2 = 12
    integer, public, parameter :: unit3 = 13
    integer, public, parameter :: unit4 = 14
    end module
