      subroutine emagnetic(ltot)
! Written by A.D.Guclu, Feb 2004.  Modified by Cyrus Umrigar
! Magnetic energies due to excess of angular momentum and spin are calculated.
! We also verify that all the determinants have same angular momentum

      use control_mod
      use dorb_mod
      use coefs_mod
      use dets_mod
      use numbas_mod
      use basis2_mod
      use basis3_mod
      use contrl_per_mod
      implicit real*8(a-h,o-z)

      common /dot/    w0,we,bext,emag,emaglz,emagsz,glande,p1,p2,p3,p4,rring

      if(numr.eq.1) then
        write(6,'(''Warning: emagnetic is not correctly implemented for numr=1'')')
        write(6,'(''Setting ltot = 0, emaglz = 0, emagsz = 0 (we assume bext = 0'')')
        ltot = 0.
        emaglz = 0.
        emagsz = 0.
        return
      endif

      write(6,'(''l_bas'',20i4)') (l_bas(ibas),ibas=1,nbasis)

! If complex orbitals are used it calculates total L here.  Otherwise it is inputted.
      if(ibasis.eq.3) then
        do 60 idet=1,ndet
          ltoti=0
          do 50 iel=1,nup+ndn
! Find angular mom. of the first non-zero basis function.
! Warning: we assume without verification that all the basis functions of a
! given orbital have same l, as should be the case for a "restricted" calculation
              nonzero_coef=0
              ibas=0
              do 40 while(nonzero_coef.eq.0)
                ibas=ibas+1
                if(coef(ibas,iworbd(iel,idet),1).ne.0.d0) then
                  nonzero_coef=1
                  if(numr.eq.0) then
! Fock-Darwin basis
                    ltoti=ltoti+m_fd(ibas)
                   else
! Radial fn. times complex spherical harmonic (should this be m_bas instead of l_bas?)
                    ltoti=ltoti+l_bas(ibas)
                  endif
                endif
                if(ibas.gt.nbasis) stop 'all the coefficients are zero in emagnetic.f'
   40         enddo
   50       enddo
!       save the total angular momentum of the first determinant and
!       keep evaluating ltot for remaining determinants for debuging:
            if(idet.eq.1) then
              ltot=ltoti
             elseif(ltot.ne.ltoti) then
              stop 'determinants have different total angular momentum'
            endif
   60   enddo
      endif

! calculate magnetic energy due to angular momentum:
      emaglz=-0.5d0*bext*ltot
! calculate magnetic energy due to spin (zeeman term):
      emagsz=-0.25d0*glande*bext*(nup-ndn)
      write(6,*)
      write(6,'(''determinantal angular momentum, ltot ='',t31,i10)') ltot
      write(6,'(''angular mom. magnetic energy ='',t31,f10.5)') emaglz
      write(6,'(''spin magnetic energy ='',t31,f10.5)') emagsz

      return
      end
