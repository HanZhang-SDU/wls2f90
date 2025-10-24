module convert
    use iso_fortran_env, only: iostat_end
    use share, only: char_string_length, unit1=>unit3, unit2=>unit4
    implicit none (type, external)
    private
    character(len=*), parameter :: lower_case_letters =&
        'abcdefghijklmnopqrstuvwxyz'
    character(len=*), parameter :: upper_case_letters =&
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    character(len=*), parameter :: letters = lower_case_letters//&
        upper_case_letters
    character(len=*), parameter :: under_score = '_'
    character(len=*), parameter :: space = ' '
    character(len=*), parameter :: decimal_digits = '0123456789'
    character(len=*), parameter :: decimal_point = '.'
    character(len=*), parameter :: operators = '+-*/^'
    character(len=*), parameter :: delimiters = '()'
    character(len=*), parameter :: function_call = '[]'
    character(len=*), parameter :: char_set = letters//under_score//space//&
        decimal_digits//decimal_point//operators//delimiters//function_call
    character(len=132), dimension(:), allocatable :: doc
    integer, parameter :: max_line_len = 132, max_num_of_lines = 255
    integer :: num_of_lines
    public :: convert_file
    contains


        function classify_char(c) result(res)
            character(len=1), intent(in) :: c
            integer :: res
            if(INDEX(letters, c)/=0) then
                res = 1
            elseif(c=='_') then
                res = 2
            elseif(INDEX(decimal_digits, c)/=0) then
                res = 3
            elseif(c=='.') then
                res = 4
            elseif(INDEX(operators, c)/=0) then
                if(c/='^') then
                    res = 5
                else
                    res = 6
                endif
            elseif(INDEX(delimiters, c)/=0) then
                res = 7
            elseif(c=='[') then
                res = 8
            elseif(c==']') then
                res = 9
            elseif(c==' ') then
                res = 10
            else
                res = -1
            endif
            end function


        function new_token_type(c) result(res)
            character(len=1), intent(in) :: c
            integer :: res
            integer :: i
            i = classify_char(c)
            if(i==1) then
                res = 1
            elseif(i==3.or.i==4) then
                res = 2
            elseif(i==6) then
                res = 3
            else
                res = 4
            endif
            end function


        subroutine refresh_token(current_token, current_char, current_token_type)
            character(len=:), intent(inout), allocatable :: current_token
            character(len=1), intent(in) :: current_char
            integer, intent(out) :: current_token_type
            current_token_type = new_token_type(current_char)
            if(current_token_type == 3) then
                current_token = '**'
            elseif(current_token_type == 4) then
                if(current_char == '[') then
                    current_token = '('
                elseif(current_char == ']') then
                    current_token = ')'
                else
                    current_token = current_char
                endif
            else
                current_token = current_char
            endif
            end subroutine


        subroutine refresh_line(line, current_token, current_char, current_token_type, tstat, tmsg)
            character(len=*), intent(inout) :: line
            character(len=:), intent(inout), allocatable :: current_token
            character(len=1), intent(in) :: current_char
            integer, intent(out) :: current_token_type
            integer, intent(out) :: tstat
            character(len=*), intent(out) :: tmsg
            if(LEN_TRIM(line) + LEN(current_token) >= max_line_len) then
                line = TRIM(line)//'&'
                write(unit=unit2, fmt='(A)', iostat=tstat, iomsg=tmsg) TRIM(line)
                if(tstat/=0) then
                    return
                endif
                num_of_lines = num_of_lines + 1
                if(num_of_lines > max_num_of_lines) then
                    tstat = 1
                    tmsg = 'error: file is too long to fit in 255 lines.'
                    return
                endif
                line = current_token
                call refresh_token(current_token, current_char, current_token_type)
            else
                line = TRIM(line)//current_token
                call refresh_token(current_token, current_char, current_token_type)
            endif
            end subroutine


        subroutine read_write(tstat, tmsg)
            integer, intent(out) :: tstat
            character(len=*), intent(out) :: tmsg
            character(len=1) :: current_char
            character(len=:), allocatable :: current_token
            integer :: char_type, current_token_type
            character(len=132) :: line
            tstat = 0
            tmsg = ''
            current_token_type = -1
            line = ''
            do
                read(unit=unit1, iostat=tstat, iomsg=tmsg) current_char
                if(tstat==iostat_end) then
                    tstat=0
                    tmsg=''
                    exit
                elseif(tstat/=0) then
                    return
                endif
                char_type = classify_char(current_char)
                if(char_type < 0) then
                    tstat = 1
                    tmsg = "error: Wolfram script contains character "//"'"//&
                        current_char//&
                        "', which is not in the allowed character set."
                    return
                elseif(char_type == 10) then   ! skip space
                    cycle
                endif
                if(current_token_type == 1) then    ! current token is a name
                    if(char_type==1.or.char_type==2.or.char_type==3) then
                        current_token = current_token//current_char
                    else
                        call refresh_line(line, current_token, current_char, current_token_type, tstat, tmsg)
                        if(tstat/=0) then
                            return
                        endif
                    endif
                elseif(current_token_type == 2) then    ! current token is a number.
                    if(char_type==3.or.char_type==4) then
                        current_token = current_token//current_char
                    else
                        if(index(current_token, '.') == 0) then
                            current_token = current_token//'.0'
                        endif
                        call refresh_line(line, current_token, current_char, current_token_type, tstat, tmsg)
                        if(tstat/=0) then
                            return
                        endif
                    endif
                elseif(current_token_type == 3) then    ! current token is an exponential.
                    if(char_type==3.or.char_type==4) then
                        current_token = current_token//current_char
                    else
                        call refresh_line(line, current_token, current_char, current_token_type, tstat, tmsg)
                        if(tstat/=0) then
                            return
                        endif
                    endif
                elseif(current_token_type == 4) then    ! current token is an operator or delimiter or function call. 
                        call refresh_line(line, current_token, current_char, current_token_type, tstat, tmsg)
                        if(tstat/=0) then
                            return
                        endif
                elseif(current_token_type < 0) then     ! current token is not allocated.
                    if(current_char/='-') then
                        current_token = 'res=res+'
                    else
                        current_token = 'res=res'
                    endif
                    call refresh_line(line, current_token, current_char, current_token_type, tstat, tmsg)
                endif
            enddo
            call refresh_line(line, current_token, current_char, current_token_type, tstat, tmsg)
            if(LEN_TRIM(line)>0.and.LEN_TRIM(line)<max_line_len) then
                write(unit=unit2, fmt='(A)', iostat=tstat, iomsg=tmsg) TRIM(line)
                if(tstat/=0) then
                    return
                endif
                num_of_lines = num_of_lines + 1
                if(num_of_lines > max_num_of_lines) then
                    tstat = 1
                    tmsg = 'error: file is too long to fit in 255 lines.'
                    return
                endif
            endif
            end subroutine


        subroutine convert_file(wls_file, f90_file, tstat, tmsg)
            character(len=*), intent(in) :: wls_file, f90_file
            integer, optional, intent(out) :: tstat
            character(len=*), optional, intent(out) :: tmsg
            integer :: tstat_tmp
            character(len=char_string_length) :: tmsg_tmp
            tstat_tmp = 0
            num_of_lines = 0
            if(present(tstat)) then
                tstat = tstat_tmp
            endif
            if(present(tmsg)) then
                tmsg = tmsg_tmp
            endif
            open(unit=unit1, file=TRIM(wls_file), access='stream', status='old',&
                action='read', iostat=tstat_tmp, iomsg=tmsg)
            if(tstat_tmp/=0) then
                if(present(tstat)) then
                    tstat = tstat_tmp
                endif
                if(present(tmsg)) then
                    tmsg = tmsg_tmp
                endif
                return
            endif
            open(unit=unit2, file=TRIM(f90_file), status='replace',&
                action='write', iostat=tstat_tmp, iomsg=tmsg)
            if(tstat_tmp/=0) then
                if(present(tstat)) then
                    tstat = tstat_tmp
                    tmsg = tmsg_tmp
                endif
                close(unit=unit1)
                return
            endif
            call read_write(tstat=tstat_tmp, tmsg=tmsg_tmp)
            if(tstat_tmp/=0) then
                if(present(tstat)) then
                    tstat = tstat_tmp
                endif
                if(present(tmsg)) then
                    tmsg = tmsg_tmp
                endif
                close(unit=unit1)
                close(unit=unit2)
                return
            endif
            end subroutine


    end module
