      subroutine checkjas2(scalek,isp,ncnstr,diff,ipr,iprin,icalcul_diff)
! Written by Cyrus Umrigar
!:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
! Prints out the values of the Jastrow factor and various partial    :::
! 1st and 2nd partial derivatives on a non-uniform grid and          :::
! imposes various prejudices as regards the signs of these.          :::
! The normalization is such that the value when both electrons are   :::
! at the nucleus is 1.                                               :::
! Note: |t| <= u <= s  is the allowed range of the variables and     :::
! the wf must be even in t (non-spin polarized system)               :::
! The penalty diffs are calculated only if icalcul_diff>=1.          :::
!                                                                    :::
! CONDITIONS IMPOSED ON JASTROW                                      :::
! Note that the u-dependence of psi comes only from the Jastrow      :::
! whereas the s and t dependence comes from both parts of psi.       :::
! Hence, the conditions on u should always be true, but the          :::
! conditions involving s and t make assumptions on the determinantal :::
! part.  It is assumed that both parts of psi have the same behaviour:::
! and assist each other, rather than fighting each other.  This      :::
! assumption is in general not valid everywhere.  All the conditions :::
! are true for the special case of a He wavefn using a single Slater :::
! basis function in the determinantal part.                          :::
!                                                                    :::
! The conditions imposed on the Jastrow factor are:                  :::
! (Note the order here is different than in the program.)            :::
! (The exponent of the Jastrow is written as c=a/b                   :::
!                                                                    :::
! 1) dc/du  >0  because electrons want to stay apart                 :::
! 2) d2c/du2<0  flatten out at large u                               :::
!               The linear term is known at u=0 and so if this is    :::
!               subtracted out the remainder is quadratic at u=0.    :::
!                                                                    :::
! 3) dc/ds  <0    x    o------->                                     :::
! 4) d2c/ds2>0       o------->                                       :::
!               - the effective exponent of psi starts out at Z      :::
!               at s=0 and goes to some smaller value at large s     :::
!               The linear term is known at s=0 and so if this is    :::
!               subtracted out the remainder is quadratic at s=0.    :::
!                                                                    :::
! 5) dc/dt  >0      o----> x      o---->                             :::
! 6) d2c/dt2>0  if the electrons start at t=0 and one moves towards  :::
!               the nucleus and one away, then the increase in psi   :::
!               from the one going in is larger than the decrease    :::
!               from the one going out.  At t=0, the linear term is  :::
!               zero since the 2 exponents start out the same and    :::
!               get different for t.ne.0.  The absence of the linear :::
!               term is automatically enforced since only even powers:::
!               of t are included.                                   :::
!                                                                    :::
! 7) b      >0  It is 1 for s=u=t=0, so if it becomes negative it    :::
!               must go through 0 and then Jastrow is +- infinite.   :::
!           >1  We do not want it to get even close to 0, so we use  :::
!               a penalty exp(1-bot)-1 that kicks in when bot<1.     :::
!                                                                    :::
! 8) db/du  >0  These are attempts to make sure that b does not      :::
! 9) db/ds  >0  get small.  What I really wanted to do is have b     :::
!10) db/dt  >0  be non-decreasing along the 3 edges of the           :::
!               tetrahedron emanating from s=u=t=0.  So, what I      :::
!               should impose is                                     :::
!               db/ds>=0,                                            :::
!               db/ds+db/du>=0,                                      :::
!               db/ds+db/du+db/dt>=0.                                :::
!:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      use atom_mod
      use contr2_mod
      implicit real*8(a-h,o-z)


      parameter (MDIM=9)

      common /chck/ bot

      dimension diff(*)
      dimension cora(MDIM,MDIM,2),bota(MDIM,MDIM,2)
!JT      data zero,one/0.d0,1.d0/
      data itranp,smin,d1m1,eps,eps2/2,1.d-6,.1,.01,1.d-10/

!  **Warning: Assume there is just one nucleus
      scalep=d1m1*znuc(iwctype(1))

! Note itrank=1 if isc=2
!             2        3
      nstep=MDIM-1
      smax=(one-eps)/scalep
      step=(smax-smin)/nstep-eps2
      itrank=isc-1
      if(iprin.ge.1) then
        write(6,*) 'smin,smax,step,scalep,scalek,itrank'
        write(6,'(5f10.5,i5)') smin,smax,step,scalep,scalek,itrank
        write(6,*) '  s     u    t     pade     bot     -dcds   dcdu    dcdt    ds+dt   ds-dt'
      endif

      ncnstr=0
      sold1=zero
      sold2=zero
      is=0
      do 30 sss=smin,smax,step
        if(iprin.eq.1) write(6,*)
        is=is+1
        if(is.gt.MDIM) stop 'is exceeds MDIM'
        uold1=zero
        uold2=zero
        iu=0
        do 20 uuu=eps2,sss,step
          iu=iu+1
          if(iu.gt.MDIM) stop 'iu exceeds MDIM'
          told1=zero
          told2=zero
          it=0
          do 10 ttt=zero,uuu+eps2,step
          it=it+1
! Transform from print scaled variable to physical variable
          if(itranp.eq.1) then
            s=-dlog(one-scalep*sss)/scalep
            t=-dlog(one-scalep*ttt)/scalep
            u=-dlog(one-scalep*uuu)/scalep
           elseif(itranp.eq.2) then
            s=sss/(one-scalep*sss)
            t=ttt/(one-scalep*ttt)
            u=uuu/(one-scalep*uuu)
          endif

          call pade(u,s,t,cor,isp)

          push=one/(one+s*s)

          if(ipos.ne.0) then
            ncnstr=ncnstr+1
            if(ijas.eq.2.or.ijas.eq.3) then
              if(bot.lt.one) then
                 if(icalcul_diff.ge.1) diff(ncnstr)=push*0.01d0*(exp(10*(one-bot))-one)*ipos
               else
                if(icalcul_diff.ge.1) diff(ncnstr)=zero
              endif
            endif
          endif

          if(idcds.ne.0) then
            if(is.gt.iu) then
              ncnstr=ncnstr+1
              dcds=cor-cora(it,iu,1)
              if(icalcul_diff.ge.1) diff(ncnstr)=push*dmin1(-dcds,zero)*idcds
             else
              dcds=zero
            endif
          endif
          if(idbds.ne.0) then
            if(is.gt.iu) then
              ncnstr=ncnstr+1
              dbds=bot-bota(it,iu,1)
              if(icalcul_diff.ge.1) diff(ncnstr)=push*dmin1(dbds,zero)*idbds
             else
              dbds=zero
            endif
          endif

          if(id2cds.ne.0) then
            if(is.gt.iu+1) then
              ncnstr=ncnstr+1
              d2cds=(cor-cora(it,iu,1))/(s-sold1)-(cora(it,iu,1)-cora(it,iu,2))/(sold1-sold2)
              if(icalcul_diff.ge.1) diff(ncnstr)=push*dmin1(d2cds,zero)*id2cds
             else
              d2cds=zero
            endif
          endif

          if(idcdu.ne.0) then
            if(iu.gt.it) then
              ncnstr=ncnstr+1
              dcdu=cor-cora(it,iu-1,1)
              if(icalcul_diff.ge.1) diff(ncnstr)=push*dmin1(dcdu,zero)*idcdu
             else
              dcdu=zero
            endif
          endif
          if(idbdu.ne.0) then
            if(iu.gt.it) then
              ncnstr=ncnstr+1
              dbdu=bot-bota(it,iu-1,1)
              if(icalcul_diff.ge.1) diff(ncnstr)=push*dmin1(dbdu,zero)*idbdu
             else
              dbdu=zero
            endif
          endif

          if(id2cdu.ne.0) then
            if(iu.gt.it+1) then
              ncnstr=ncnstr+1
              d2cdu=(cor-cora(it,iu-1,1))/(u-uold1)-(cora(it,iu-1,1)-cora(it,iu-2,1))/(uold1-uold2)
              if(icalcul_diff.ge.1) diff(ncnstr)=push*dmin1(-d2cdu,zero)*id2cdu
             else
              d2cdu=zero
            endif
          endif

          if(idcdt.ne.0) then
            if(it.gt.1) then
              ncnstr=ncnstr+1
              dcdt=cor-cora(it-1,iu,1)
              if(icalcul_diff.ge.1) diff(ncnstr)=push*dmin1(dcdt,zero)*idcdt
             else
              dcdt=zero
            endif
          endif
          if(idbdt.ne.0) then
            if(it.gt.1) then
              ncnstr=ncnstr+1
              dbdt=bot-bota(it-1,iu,1)
              if(icalcul_diff.ge.1) diff(ncnstr)=push*dmin1(dbdt,zero)*idbdt
             else
              dbdt=zero
            endif
          endif

          if(id2cdt.ne.0) then
            if(it.gt.2) then
              ncnstr=ncnstr+1
              d2cdt=(cor-cora(it-1,iu,1))/(t-told1)-(cora(it-1,iu,1)-cora(it-2,iu,1))/(told1-told2)
              if(icalcul_diff.ge.1) diff(ncnstr)=push*dmin1(d2cdt,zero)*id2cdt
             else
              d2cdt=zero
            endif
          endif

          if(dcds.ne.zero .and. dcdt.ne.zero) then
            dspdt=dcds+dcdt
            dsmdt=dcds-dcdt
           else
            dspdt=zero
            dsmdt=zero
          endif

          if(iprin.ge.1.and.ipr.ge.-1) then
            if((ijas.eq.2.or.ijas.eq.3).and. bot.lt.1.) write(6,'(''**Warning bot<1'',4f9.3)')s,u,t,bot
            if(-dcds.lt.0.) write(6,'(''**Warning-dcds<0'',3f9.3,d9.2)') s,u,t,-dcds
            if( dcdu.lt.0.) write(6,'(''**Warning dcdu<0'',3f9.3,d9.2)') s,u,t,dcdu
            if( dcdt.lt.0.) write(6,'(''**Warning dcdt<0'',3f9.3,d9.2)') s,u,t,dcdt
            if( d2cds.lt.0.) write(6,'(''**Warning d2cds<0'',3f9.3,d9.2)') s,u,t,d2cds
            if(-d2cdu.lt.0.) write(6,'(''**Warning-d2cdu<0'',3f9.3,d9.2)') s,u,t,-d2cdu
            if( d2cdt.lt.0.) write(6,'(''**Warning d2cdt<0'',3f9.3,d9.2)') s,u,t,d2cdt
            if( dbds.lt.0.) write(6,'(''**Warning dbds<0'',3f9.3,d9.2)') s,u,t,dbds
            if( dbdu.lt.0.) write(6,'(''**Warning dbdu<0'',3f9.3,d9.2)') s,u,t,dbdu
            if( dbdt.lt.0.) write(6,'(''**Warning dbdt<0'',3f9.3,d9.2)') s,u,t,dbdt
            write(6,'(3f6.2,1x,f9.5,6f8.4)') s,u,t,cor,bot,-dcds,dcdu,dcdt,-dspdt,-dsmdt
          endif

          if(is.gt.1) then
            cora(it,iu,2)=cora(it,iu,1)
            bota(it,iu,2)=bota(it,iu,1)
          endif
          cora(it,iu,1)=cor
          bota(it,iu,1)=bot

          told2=told1
   10     told1=t
        uold2=uold1
   20   uold1=u
      sold2=sold1
   30 sold1=s
      if(iprin.ge.1)write(6,'(''Number of constraint pts='',i5)') ncnstr
      return
      end

!-----------------------------------------------------------------------------

      subroutine pade(u,s,t,cor,isp)

      use atom_mod
      use const_mod
      use contr2_mod
      use wfsec_mod
      use jaspar_mod
      use bparm_mod
      implicit real*8(a-h,o-z)

!JT      parameter (one=1.d0,half=0.5d0)




      iwf=1

      iss=isp
      sspinn=one
      sspin=sspinn
! Warning: Next line needs to be fixed
      ipar=0

      r1=half*(s+t)
      r2=half*(s-t)

      if(ijas.eq.3) then
        if(nspin2.eq.1.and.isp.gt.1) iss=1
      endif

      psic=psi(u,r1,r2,1)

      if(ijas.eq.3) then
        if(nspin2b.eq.1.and.nocuspb.eq.0.and.isp.gt.1) sspinn=half
        psibc=psib(u,iss,ipar)
        if(nspin2.gt.1.and.isp.eq.1) then
          psi1=psia(r1,1)
          iss=2
          psi2=psia(r2,1)
          psiac=psi1+psi2
         else
          psiac=psia(r1,1)+psia(r2,1)
        endif
        psic=psic+psiac/(nelec-1)+psibc/ncent
      endif

      cor=psic

      return
      end
