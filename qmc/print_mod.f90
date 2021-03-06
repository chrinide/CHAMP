module print_mod

  use basic_tools_mod
  use constants_mod
  use variables_mod
  use objects_mod
  use parser_tools_mod

  integer                      :: objects_print_at_each_block_nb = 0
  integer, allocatable         :: objects_print_at_each_block_index (:)
  integer                      :: objects_print_at_each_block_nb_save = 0
  integer, allocatable         :: objects_print_at_each_block_index_save (:)

  contains

!===========================================================================
  subroutine print_menu
!---------------------------------------------------------------------------
! Description : menu for printing objects
!
! Created     : J. Toulouse, 29 Nov 2005
! Modified    : J. Toulouse, 15 Nov 2006, print at each block
!---------------------------------------------------------------------------
  implicit none

! local
  character(len=max_string_len_rout), save :: lhere = 'print_menu'
  integer objects_to_print_now_nb, objects_to_print_block_nb
# if defined (PATHSCALE)
   character(len=max_string_len) :: objects_to_print_now (max_string_array_len) ! for pathscale compiler
   character(len=max_string_len) :: objects_to_print_block (max_string_array_len) ! for pathscale compiler
# else
   character(len=max_string_len), allocatable :: objects_to_print_now (:)
   character(len=max_string_len), allocatable :: objects_to_print_block (:)
# endif
  integer obj_i

! begin
  write(6,*)
  write(6,'(a)') 'Beginning of print menu ----------------------------------------------------------------------------------'

  objects_to_print_now_nb = 0
  objects_to_print_block_nb = 0

! loop over menu lines
  do
  call get_next_word (word)

  select case (trim(word))

  case ('help')
   write(6,*)
   write(6,'(a)') 'HELP for print menu:'
   write(6,'(a)') 'print'
   write(6,'(a)') '  now ... end: list of objects to print now'
   write(6,'(a)') '  block ... end: list of objects to print at each block'
   write(6,'(a)') 'end'
   write(6,*)

  case ('now')
# if defined (PATHSCALE)
   call get_next_value_list_string ('objects_to_print_now', objects_to_print_now, objects_to_print_now_nb) ! for pathscale compiler
# else
   call get_next_value_list ('objects_to_print_now', objects_to_print_now, objects_to_print_now_nb)
# endif

!  provide objects
   do obj_i = 1, objects_to_print_now_nb
    call object_provide (objects_to_print_now (obj_i))
   enddo

!  write objects on separate lines
   do obj_i = 1, objects_to_print_now_nb
      call object_write (objects_to_print_now (obj_i))
   end do

  case ('block')
# if defined (PATHSCALE)
   call get_next_value_list_string ('objects_to_print_block', objects_to_print_block, objects_to_print_block_nb) ! for pathscale compiler
# else
   call get_next_value_list ('objects_to_print_block', objects_to_print_block, objects_to_print_block_nb)
# endif

!  request printing of objects at each block
   do obj_i = 1, objects_to_print_block_nb
    call object_print_at_each_block_request (objects_to_print_block (obj_i))
   enddo

  case ('end')
   exit

  case default
   call die (lhere, 'unknown keyword >'+trim(word)+'<.')
  end select

  enddo ! end loop over menu lines

  write(6,'(a)') 'End of print menu ----------------------------------------------------------------------------------------'

  end subroutine print_menu

! ===================================================================================
  subroutine object_print_at_each_block_request (object_name)
! ----------------------------------------------------------------------------------
! Description   : request for printing an object at each block
!
! Created       : J. Toulouse, 15 Nov 2006
! -----------------------------------------------------------------------------------
  implicit none

! input
  character(len=*), intent(in) :: object_name

! local
  character(len=max_string_len_rout), save :: lhere = 'object_print_at_each_block_request'
  integer object_ind


! begin
  call object_add_once_and_index (object_name, object_ind)

  call append_once (objects_print_at_each_block_index, object_ind)
  objects_print_at_each_block_nb = size(objects_print_at_each_block_index)

  write(6,'(4a)') trim(lhere),': object ', trim(object_name),' will be printed at each block.'

 end subroutine object_print_at_each_block_request

! ===================================================================================
  subroutine objects_print_at_each_block
! -----------------------------------------------------------------------------------
! Description   : print requested objects at each block
!
! Created       : J. Toulouse, 15 Nov 2006
! -----------------------------------------------------------------------------------
  implicit none

! local
  integer obj_i

! begin
  do obj_i = 1, objects_print_at_each_block_nb
    call object_provide_by_index (objects_print_at_each_block_index (obj_i))
    call object_write_by_index (objects_print_at_each_block_index (obj_i))
  enddo

 end subroutine objects_print_at_each_block

! ===================================================================================
  subroutine reinit_objects_print_at_each_block
! -----------------------------------------------------------------------------------
! Description   : reinitialize array of requested objects to be printed at each block
!
! Created       : J. Toulouse, 15 Nov 2006
! -----------------------------------------------------------------------------------
  implicit none

  objects_print_at_each_block_nb = 0
  call release ('objects_print_at_each_block_index', objects_print_at_each_block_index)

 end subroutine reinit_objects_print_at_each_block

! ===================================================================================
  subroutine save_objects_print_at_each_block
! -----------------------------------------------------------------------------------
! Description   : save array of requested objects to be printed at each block
!
! Created       : J. Toulouse, 08 Jun 2012
! -----------------------------------------------------------------------------------
  implicit none

  objects_print_at_each_block_nb_save = objects_print_at_each_block_nb
  call copy (objects_print_at_each_block_index, objects_print_at_each_block_index_save)

  end subroutine save_objects_print_at_each_block

! ===================================================================================
  subroutine restore_objects_print_at_each_block
! -----------------------------------------------------------------------------------
! Description   : restore array of requested objects to be printed at each block
!
! Created       : J. Toulouse, 08 Jun 2012
! -----------------------------------------------------------------------------------
  implicit none

  objects_print_at_each_block_nb = objects_print_at_each_block_nb_save
  call move (objects_print_at_each_block_index_save, objects_print_at_each_block_index)

  end subroutine restore_objects_print_at_each_block

end module print_mod
