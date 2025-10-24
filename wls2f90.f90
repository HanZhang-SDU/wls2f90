program main
    !This is a program that can convert wolfram language script formula into 
    !modern fortran format.
    !syntax: wls2f90 [option] wls_file[_list] f90_file[_list]
    !options:
    !   -s convert single file
    !   -m convert multiple files specified in wls_file[_list]
    !the basic call
    !   wls2f90 wls.txt fortran.f90
    !convert single file, i.e., it's equivalent to
    !   wls2f90 -s wls.txt fortran.f90
    use share, only: char_string_length, fortran_extension, unit1=>unit1,&
        unit2=>unit2
    use iso_fortran_env, only: iostat_end
    use convert
    implicit none (type, external)
    character(len=char_string_length) :: wls_file, f90_file
    integer :: tstat
    character(len=char_string_length) :: tmsg
    character(len=char_string_length) :: first_parameter
    character(char_string_length) :: wls_file_list, f90_file_list
    integer :: i
    tstat = 0
    tmsg = ''
    !command line flag that controls whether to transfer single (-s) file or
    !multiple (-m) file. 
    call get_command_argument(1, first_parameter, status=tstat)
    if(tstat/=0) then
        tmsg = "Syntax error: wls2f90 [option] 'wls_file[_list]' 'f90_file[_list]'"
        print *, TRIM(tmsg)
        return
    endif
    if(first_parameter=='-m') then
        call get_command_argument(2, wls_file_list, status=tstat)
        if(tstat/=0) then
            tmsg = "Syntax error: wls2f90 [option] 'wls_file[_list]' 'f90_file[_list]'"
            print *, TRIM(tmsg)
            return
        endif
        call get_command_argument(3, f90_file_list, status=tstat)
        if(tstat/=0) then
            tmsg = "Syntax error: wls2f90 [option] 'wls_file[_list]' 'f90_file[_list]'"
            print *, TRIM(tmsg)
            return
        endif
        open(unit=unit1, file=TRIM(wls_file_list), action='read', status='old',&
            iostat=tstat, iomsg=tmsg)
        if(tstat/=0) then
            print *, TRIM(tmsg)
            return
        endif
        open(unit=unit2, file=TRIM(f90_file_list), action='write',&
            status='replace', iostat=tstat, iomsg=tmsg)
        if(tstat/=0) then
            close(unit=unit1)
            print *, TRIM(tmsg)
            return
        endif
        do
            read(unit=unit1, fmt='(A)', iostat=tstat, iomsg=tmsg) wls_file
            if(tstat==iostat_end) then
                close(unit=unit1)
                close(unit=unit2)
                return
            elseif(tstat/=0) then
                close(unit=unit1)
                close(unit=unit2)
                print *, TRIM(tmsg)
                return
            elseif(LEN_TRIM(wls_file)==0) then
                cycle
            endif
            f90_file = TRIM(wls_file)
            i = index(f90_file, '.')
            f90_file = f90_file(1:i-1)//fortran_extension
            write(unit=unit2, fmt='(A)', iostat=tstat, iomsg=tmsg) 'include '//&
            "'"//TRIM(f90_file)//"'"
            if(tstat/=0) then
                close(unit=unit1)
                close(unit=unit2)
                print *, TRIM(tmsg)
                return
            endif
            call convert_file(wls_file=wls_file, f90_file=f90_file,&
                tstat=tstat, tmsg=tmsg)
            if(tstat/=0) then
                print *, 'error encountered when converting '//"'"&
                    //TRIM(wls_file)&
                    //"'"//', this file was skipped.'
                print *, TRIM(tmsg)
                cycle
            endif
        enddo
    elseif(first_parameter=='-s') then
        call get_command_argument(3, wls_file, status=tstat)
        if(tstat/=0) then
            tmsg = "Syntax error: wls2f90 [option] 'wls_file[_list]' 'f90_file[_list]'"
            print *, TRIM(tmsg)
            return
        endif
        call get_command_argument(4, f90_file, status=tstat)
        if(tstat/=0) then
            tmsg = "Syntax error: wls2f90 [option] 'wls_file[_list]' 'f90_file[_list]'"
            print *, TRIM(tmsg)
            return
        endif
        call convert_file(wls_file=wls_file, f90_file=f90_file, tstat=tstat,&
            tmsg=tmsg)
        if(tstat/=0) then
            print *, TRIM(tmsg)
            return
        endif
    else
        call get_command_argument(1, wls_file, status=tstat)
        if(tstat/=0) then
            tmsg = "Syntax error: wls2f90 [option] 'wls_file[_list]' 'f90_file[_list]'"
            print *, TRIM(tmsg)
            return
        endif
        call get_command_argument(2, f90_file, status=tstat)
        if(tstat/=0) then
            tmsg = "Syntax error: wls2f90 [option] 'wls_file[_list]' 'f90_file[_list]'"
            print *, TRIM(tmsg)
            return
        endif
        call convert_file(wls_file=wls_file, f90_file=f90_file, tstat=tstat,&
            tmsg=tmsg)
        if(tstat/=0) then
            print *, TRIM(tmsg)
            return
        endif
    endif
    end program
