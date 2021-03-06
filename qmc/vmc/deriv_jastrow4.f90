      subroutine deriv_jastrow4(x,v,d2,value)
! Written by Cyrus Umrigar and Claudia Filippi
! Jastrow 4,5 must be used with one of isc=2,4,6,7,12,14,16,17
! Jastrow 6   must be used with one of isc=6,7

! When iperiodic=1, nloc=-4 (infinite quantum wire), then the "en" distance
!  used in en and een terms for the first center (ic = 1) is the distance
!  between the electron and the middle (y-axis) of the wire, rather than
!   the distance between (0,0) and an electron.  ACM, July 2010

      use all_tools_mod
      use constants_mod
      use control_mod
      use atom_mod
      use dets_mod
      use optim_mod
      use const_mod
      use dim_mod
      use contr2_mod
      use contrl_opt2_mod
      use wfsec_mod
      use contrl_per_mod
      use derivjas_mod
      use jaspar_mod
      use jaspar3_mod
      use jaspar4_mod
      use jaspar6_mod
      use bparm_mod
      use pointer_mod
      use gradhessj_nonlin_mod
      use distance_mod
      use jaso_mod
      use vardep_mod
      use cuspmat4_mod
      use pseudo_mod
      implicit real*8(a-h,o-z)

      parameter (eps=1.d-12)

!!!   added WAS
      common /jas_c_cut/ cutjasc,icutjasc
!!!

      common /focktmp/ fc,fcu,fcuu,fcs,fcss,fct,fctt,fcst,fcus,fcut

      dimension x(3,*),v(3,*)
!     dimension uu(-3:nord),ss(-3:nord),tt(-3:nord),rri(-3:nord),rrj(-3:nord)
      dimension uu(-3:max(nord,nordb,nordc)),ss(-3:max(nord,norda,nordc)),tt(-3:max(nord,norda,nordc)),rri(-3:max(nord,norda,nordc)) &
     &,rrj(-3:max(nord,norda,nordc))

      ndim1=ndim-1

      fsum=0

      do 2 iparm=1,nparmj+nparms
        gvalue(iparm)=0
        d2g(iparm)=0
        didk(iparm)=0
        do 2 i=1,nelec
          g(1,i,iparm)=0
          g(2,i,iparm)=0
   2      g(3,i,iparm)=0

      do 3 isb=1,nspin2b
        d1d2b(isb)=0
   3    d2d2b(isb)=0
      do 4 it=1,nctype
        d1d2a(it)=0
   4    d2d2a(it)=0

      do 5 i=-3,-1
        uu(i)=0
        ss(i)=0
        tt(i)=0
        rri(i)=0
    5   rrj(i)=0
      uu(0)=1
      ss(0)=2
      tt(0)=1
      rri(0)=1
      rrj(0)=1

      if(igradhess.gt.0) then
        iderivk=2
      else
        iderivk=1
      endif

      if(nelec.lt.2) goto 65

! e-e and e-e-n terms
      ij=0
      do 60 i=2,nelec
      im1=i-1
      do 60 j=1,im1
      ij=ij+1

      fso(i,j)=0
      d2ijo(i,j)=0
      do 10 k=1,ndim
        fijo(k,i,j)=0
   10   fijo(k,j,i)=0

      do 11 iparm=1,nparmj+nparms
   11   go(i,j,iparm)=0

      sspinn=1
      isb=1
      ipar=0
      if(i.le.nup .or. j.gt.nup) then
        if(nspin2b.eq.2) then
          isb=2
         elseif(nocuspb.eq.0) then
          if(ndim.eq.3) then
            sspinn=half
           elseif(ndim.eq.2) then
            sspinn=third
          endif
        endif
        ipar=1
      endif

      rij=r_ee(ij)

      if(rij.gt.cutjas_ee) goto 30

      call scale_dist2(rij,uu(1),dd1,dd2,2)
      if(nparms.eq.1) call deriv_scale(rij,dk,dk2,dr,dr2,2,iderivk)


      top=sspinn*b(1,isb,iwf)*uu(1)
      topu=sspinn*b(1,isb,iwf)
      topuu=0

      bot=1+b(2,isb,iwf)*uu(1)
      botu=b(2,isb,iwf)
      botuu=0
      bot2=bot*bot


!      feeu=topu/bot-botu*top/bot2
!      feeuu=topuu-(botuu*top+2*botu*topu)/bot+2*botu**2*top/bot2
!      feeuu=feeuu/bot
! simpler expressions are :
      fee=top/bot
      feeu=topu/bot2
      feeuu=-2*feeu*botu/bot
      tempuu=feeuu
      if(isc.eq.8 .or. isc.eq.10) then
        fee=fee/scalek(iwf)
        feeu=feeu/scalek(iwf)
        feeuu=feeuu/scalek(iwf)
      endif
      fee=fee-asymp_jasb(ipar+1,iwf)


      do 20 iord=2,nordb
        uu(iord)=uu(1)*uu(iord-1)
        fee=fee+b(iord+1,isb,iwf)*uu(iord)
        feeu=feeu+b(iord+1,isb,iwf)*iord*uu(iord-1)
   20   feeuu=feeuu+b(iord+1,isb,iwf)*iord*(iord-1)*uu(iord-2)

! for scale derivatives we also need feeuuu:
      if(nparms.eq.1) then
        if(isc.eq.8 .or. isc.eq.10) then
          stop 'scalek opt not fully implemented for isc=8,10'
        endif
        feeuuu=-3*tempuu*botu/bot
        do 21 iord=3,nordb
   21     feeuuu=feeuuu+b(iord+1,isb,iwf)*iord*(iord-1)*(iord-2)*uu(iord-3)
      endif

!      feeuu=feeuu*dd1*dd1+feeu*dd2
!      feeu=feeu*dd1/rij
! we will need feeuu and feeu later
      tempuu=feeuu*dd1*dd1+feeu*dd2
      tempu=feeu*dd1/rij

      fso(i,j)=fso(i,j) + fee
      do 22 k=1,ndim
        fijo(k,i,j)= fijo(k,i,j) + tempu*rvec_ee(k,ij)
   22   fijo(k,j,i)= fijo(k,j,i) - tempu*rvec_ee(k,ij)
      d2ijo(i,j)=d2ijo(i,j)+2.*(tempuu+ndim1*tempu)

!     v(1,i)=v(1,i) + tempu*rvec_ee(1,ij)
!     v(2,i)=v(2,i) + tempu*rvec_ee(2,ij)
!     v(3,i)=v(3,i) + tempu*rvec_ee(3,ij)
!     v(1,j)=v(1,j) - tempu*rvec_ee(1,ij)
!     v(2,j)=v(2,j) - tempu*rvec_ee(2,ij)
!     v(3,j)=v(3,j) - tempu*rvec_ee(3,ij)

!     d2 =d2 + two*(tempuu+ndim1*feeu)

! derivatives of wave function wrt b(1),b(2) and rest of b(i)

      iparma=nparma(1)
      do 23 it=2,nctype
   23  iparma=iparma+nparma(it)

      iparm0=iparma+nparms
      if(isb.eq.2) iparm0=iparm0+nparmb(1)
      do 25 jparm=1,nparmb(isb)
        iparm=iparm0+jparm

        if(iwjasb(jparm,isb).eq.1) then
          top=sspinn*uu(1)
          topu=sspinn
          topuu=zero

          bot=one+b(2,isb,iwf)*uu(1)
          botu=b(2,isb,iwf)
          botuu=zero
          bot2=bot*bot

          botasymp=1+b(2,isb,iwf)*asymp_r_ee(iwf)

          gee=top/bot-sspinn*asymp_r_ee(iwf)/botasymp
!         geeu=topu/bot-botu*top/bot2
!         geeuu=topuu-(botuu*top+2*botu*topu)/bot+2*botu**2*top/bot2
!         geeuu=geeuu/bot
          geeu=topu/bot2
          geeuu=-2*botu*geeu/bot
          if(isc.eq.8 .or. isc.eq.10) then
            gee=gee/scalek(iwf)
            geeu=geeu/scalek(iwf)
            geeuu=geeuu/scalek(iwf)
          endif

          if(igradhess.gt.0 .and. nparms.eq.1) then
            if(isc.eq.8 .or. isc.eq.10) then
              stop 'scalek opt not fully implemented for isc=8,10'
            endif
            asympterm=sspinn/(botasymp*botasymp)*dasymp_r_ee(iwf)
!            asympterm=0
            didk(iparm)=didk(iparm)+geeu*dk-asympterm
          endif

         elseif(iwjasb(jparm,isb).eq.2) then
          top=-sspinn*b(1,isb,iwf)*uu(1)*uu(1)
          topu=-sspinn*2*b(1,isb,iwf)*uu(1)
          topuu=-sspinn*2*b(1,isb,iwf)

          bot0=one+b(2,isb,iwf)*uu(1)
          bot=bot0*bot0
          botu=2*bot0*b(2,isb,iwf)
          botuu=2*b(2,isb,iwf)*b(2,isb,iwf)
          bot2=bot*bot

          botasymp=1+b(2,isb,iwf)*asymp_r_ee(iwf)
          botasymp2=botasymp*botasymp

          gee=top/bot+sspinn*b(1,isb,iwf)*asymp_r_ee(iwf)**2/botasymp2
!          geeu=topu/bot-botu*top/bot2
!          geeuu=topuu-(botuu*top+2*botu*topu)/bot+2*botu**2*top/bot2
!          geeuu=geeuu/bot
          geeu=topu/(bot*bot0)
          geeuu=topuu*(1-2*b(2,isb,iwf)*uu(1))/bot2
          if(isc.eq.8 .or. isc.eq.10) then
            gee=gee/scalek(iwf)
            geeu=geeu/scalek(iwf)
            geeuu=geeuu/scalek(iwf)
          endif

          if(igradhess.gt.0 .or. l_opt_jas_2nd_deriv) then
            if(isc.eq.8 .or. isc.eq.10) then
              d2d2b(isb)=d2d2b(isb)- &
     &2*(top*uu(1)/(bot*bot0)+sspinn*b(1,isb,iwf)*asymp_r_ee(iwf)**3/(1+b(2,isb,iwf)*asymp_r_ee(iwf))**3)/scalek(iwf)
              d1d2b(isb)=d1d2b(isb)- &
     &(sspinn*uu(1)*uu(1)/bot-sspinn*asymp_r_ee(iwf)**2/(1+b(2,isb,iwf)*asymp_r_ee(iwf))**2)/scalek(iwf)
            else
              d2d2b(isb)=d2d2b(isb)- &
     &2*top*uu(1)/bot/bot0-2*sspinn*b(1,isb,iwf)*asymp_r_ee(iwf)**3/(1+b(2,isb,iwf)*asymp_r_ee(iwf))**3
              d1d2b(isb)=d1d2b(isb)- &
     &sspinn*uu(1)*uu(1)/bot+sspinn*asymp_r_ee(iwf)**2/(1+b(2,isb,iwf)*asymp_r_ee(iwf))**2
            endif
            if(nparms.eq.1) then
              if(isc.eq.8 .or. isc.eq.10) then
                stop 'scalek opt not fully implemented for isc=8,10'
              endif
              asympterm=topuu*asymp_r_ee(iwf)/(botasymp*botasymp2)*dasymp_r_ee(iwf)
              didk(iparm)=didk(iparm)+geeu*dk-asympterm
            endif
          endif

         else
          iord=iwjasb(jparm,isb)-1
          if(ijas.eq.4) then
            asympiord=asymp_r_ee(iwf)**iord
            gee=uu(iord)-asympiord
            geeu=iord*uu(iord-1)
            geeuu=iord*(iord-1)*uu(iord-2)
            if(nparms.eq.1 .and. igradhess.gt.0) then
              asympterm=asympiord/asymp_r_ee(iwf)*dasymp_r_ee(iwf)
!              asympterm=0
              didk(iparm)=didk(iparm)+iord*(uu(iord-1)*dk-asympterm)
            endif
           elseif(ijas.eq.5) then
            gee=sspinn*(uu(iord)-asymp_r_ee(iwf)**iord)
            geeu=sspinn*iord*uu(iord-1)
            geeuu=sspinn*iord*(iord-1)*uu(iord-2)
          endif

        endif

        geeuu=geeuu*dd1*dd1+geeu*dd2
        geeu=geeu*dd1/rij

        go(i,j,iparm)=go(i,j,iparm)+gee
        gvalue(iparm)=gvalue(iparm)+gee

        g(1,i,iparm)=g(1,i,iparm) + geeu*rvec_ee(1,ij)
        g(2,i,iparm)=g(2,i,iparm) + geeu*rvec_ee(2,ij)
        g(3,i,iparm)=g(3,i,iparm) + geeu*rvec_ee(3,ij)
        g(1,j,iparm)=g(1,j,iparm) - geeu*rvec_ee(1,ij)
        g(2,j,iparm)=g(2,j,iparm) - geeu*rvec_ee(2,ij)
        g(3,j,iparm)=g(3,j,iparm) - geeu*rvec_ee(3,ij)

        d2g(iparm)=d2g(iparm) + two*(geeuu+ndim1*geeu)

   25 continue

! derivatives (go,gvalue and g) wrt scalek parameter
      if(nparms.eq.1) then
        if(isc.eq.8 .or. isc.eq.10) then
          stop 'scalek opt not fully implemented for isc=8,10'
        endif
        iparm=1
!        call deriv_scale(rij,dk,dk2,dr,dr2,2,iderivk)

        gee=feeu*dk-dasymp_jasb(ipar+1,iwf)*dasymp_r_ee(iwf)
        geeu=(feeuu*dk*dd1+feeu*dr)/rij
        geeuu=feeuu*dk*dd2+(feeuuu*dk*dd1+2*feeuu*dr)*dd1+feeu*dr2

        go(i,j,iparm)=go(i,j,iparm)+gee
        gvalue(iparm)=gvalue(iparm)+gee

        g(1,i,iparm)=g(1,i,iparm) + geeu*rvec_ee(1,ij)
        g(2,i,iparm)=g(2,i,iparm) + geeu*rvec_ee(2,ij)
        g(3,i,iparm)=g(3,i,iparm) + geeu*rvec_ee(3,ij)
        g(1,j,iparm)=g(1,j,iparm) - geeu*rvec_ee(1,ij)
        g(2,j,iparm)=g(2,j,iparm) - geeu*rvec_ee(2,ij)
        g(3,j,iparm)=g(3,j,iparm) - geeu*rvec_ee(3,ij)

        d2g(iparm)=d2g(iparm) + two*(geeuu+ndim1*geeu)

        if(igradhess.gt.0) then
          didk(1)=didk(1)+feeuu*dk*dk+feeu*dk2 &
     &-d2asymp_jasb(ipar+1,iwf)*dasymp_r_ee(iwf)*dasymp_r_ee(iwf)-dasymp_jasb(ipar+1,iwf)*d2asymp_r_ee(iwf)
        endif

      endif

! There are no C terms to order 1.
   30 if(nordc.le.1) goto 58

!     if(isc.ge.12) call scale_dist2(rij,uu(1),dd1,dd2,3)
      call scale_dist2(rij,uu(1),dd1,dd2,4)
      if(ijas.eq.4.or.ijas.eq.5) then
        call switch_scale2(uu(1),dd1,dd2,4)
        do 35 iord=2,nordc
   35     uu(iord)=uu(1)*uu(iord-1)
      endif

      do 57 ic=1,ncent
        it=iwctype(ic)
!       if we have an infinite wire, then for the en and een terms, for ic=1,
!         we only use the distance from the electron to the y-axis of the wire
        if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then
           ri=abs(rvec_en(2,i,ic))  ! y-component of rvec_en is dist to wire center
           rj=abs(rvec_en(2,j,ic))
        else
           ri=r_en(i,ic)
           rj=r_en(j,ic)
        endif


        if(ri.gt.cutjas_en .or. rj.gt.cutjas_en) goto 57
        do 37 k=1,ndim
   37     if(abs(rshift(k,i,ic)-rshift(k,j,ic)).gt.eps) goto 57

        call scale_dist2(ri,rri(1),dd7,dd9,3)
        call scale_dist2(rj,rrj(1),dd8,dd10,3)

        if(ijas.eq.4.or.ijas.eq.5) then
          call switch_scale2(rri(1),dd7,dd9,3)
          call switch_scale2(rrj(1),dd8,dd10,3)
        endif

!!!! WAS
        if(icutjasc .gt. 0 .or. iperiodic .ne. 0) then
!           call f_een_cuts (cutjasc, ri, rj, fcuti, fcutj, fcut,
           call f_een_cuts (cutjas_en, ri, rj, fcuti, fcutj, fcut, &
     &          dfcuti, dfcutj, d2fcuti, d2fcutj)
        endif
!!!

        if(nparms.eq.1) then
          call deriv_scale(rij,dkij,dk2ij,drij,dr2ij,4,iderivk)
          call deriv_scale(ri,dki,dk2i,dri,dr2i,3,iderivk)
          call deriv_scale(rj,dkj,dk2j,drj,dr2j,3,iderivk)
          call switch_dscale(uu(1),dd1,dd2,dkij,dk2ij,drij,dr2ij,4,iderivk)
          call switch_dscale(rri(1),dd7,dd9,dki,dk2i,dri,dr2i,3,iderivk)
          call switch_dscale(rrj(1),dd8,dd10,dkj,dk2j,drj,dr2j,3,iderivk)
        endif

        s=ri+rj
        t=ri-rj
!       u2mt2=rij*rij-t*t
        u2pst=rij*rij+s*t
        u2mst=rij*rij-s*t
!       s2mu2=s*s-rij*rij
!       s2mt2=s*s-t*t

        do 50 iord=1,nordc
!         rri(iord)=rri(1)**iord
!         rrj(iord)=rrj(1)**iord
          rri(iord)=rri(1)*rri(iord-1)
          rrj(iord)=rrj(1)*rrj(iord-1)
          ss(iord)=rri(iord)+rrj(iord)
   50     tt(iord)=rri(iord)*rrj(iord)

        fc=0
        fu=0
        fuu=0
        fi=0
        fii=0
        fj=0
        fjj=0
        fui=0
        fuj=0
        fij=0
        fuuu=0
        fuui=0
        fuuj=0
        fuii=0
        fuij=0
        fujj=0
        fiii=0
        fiij=0
        fijj=0
        fjjj=0

        ll=0
        jj=1
        jparm=1
        do 55 n=2,nordc
          do 55 k=n-1,0,-1
            if(k.eq.0) then
              l_hi=n-k-2
             else
              l_hi=n-k
            endif
            do 55 l=l_hi,0,-1
              m=(n-k-l)/2
              if(2*m.eq.n-k-l) then
                ll=ll+1
                p1=uu(k)
                p1u=k*uu(k-1)
                p1uu=k*(k-1)*uu(k-2)
                p2=ss(l)*tt(m)
                p2i=((l+m)*rri(l+m-1)*rrj(m)+m*rri(m-1)*rrj(l+m))
                p2ii=((l+m)*(l+m-1)*rri(l+m-2)*rrj(m)+m*(m-1)*rri(m-2)*rrj(l+m))
                p2j=((l+m)*rrj(l+m-1)*rri(m)+m*rrj(m-1)*rri(l+m))
                p2jj=((l+m)*(l+m-1)*rrj(l+m-2)*rri(m)+m*(m-1)*rrj(m-2)*rri(l+m))
                pc=p1*p2
                pu=p1u*p2
                puu=p1uu*p2
                ppi=p1*p2i
                pii=p1*p2ii
                pj=p1*p2j
                pjj=p1*p2jj
                pui=p1u*p2i
                puj=p1u*p2j

!                pc=uu(k)*ss(l)*tt(m)
!                pu=k*uu(k-1)*ss(l)*tt(m)
!                puu=k*(k-1)*uu(k-2)*ss(l)*tt(m)
!                ppi=uu(k)
!     &          *((l+m)*rri(l+m-1)*rrj(m)+m*rri(m-1)*rrj(l+m))
!                pii=uu(k)
!     &          *((l+m)*(l+m-1)*rri(l+m-2)*rrj(m)
!     &          +m*(m-1)*rri(m-2)*rrj(l+m))
!                pj=uu(k)
!     &          *((l+m)*rrj(l+m-1)*rri(m)+m*rrj(m-1)*rri(l+m))
!                pjj=uu(k)
!     &          *((l+m)*(l+m-1)*rrj(l+m-2)*rri(m)
!     &          +m*(m-1)*rrj(m-2)*rri(l+m))
!                pui=k*uu(k-1)
!     &          *((l+m)*rri(l+m-1)*rrj(m)+m*rri(m-1)*rrj(l+m))
!                puj=k*uu(k-1)
!     &          *((l+m)*rrj(l+m-1)*rri(m)+m*rrj(m-1)*rri(l+m))

                fc=fc+c(ll,it,iwf)*pc
                fu=fu+c(ll,it,iwf)*pu
                fuu=fuu+c(ll,it,iwf)*puu
                fi=fi+c(ll,it,iwf)*ppi
                fii=fii+c(ll,it,iwf)*pii
                fj=fj+c(ll,it,iwf)*pj
                fjj=fjj+c(ll,it,iwf)*pjj
                fui=fui+c(ll,it,iwf)*pui
                fuj=fuj+c(ll,it,iwf)*puj

! quantities needed for scale derivatives:
                if(nparms.eq.1) then

                  p1uuu=k*(k-1)*(k-2)*uu(k-3)
                  p2ij =((l+m)*rri(l+m-1)*m*rrj(m-1)             + m*(l+m)*rri(m-1)*rrj(l+m-1))
                  p2iii=((l+m)*(l+m-1)*(l+m-2)*rri(l+m-3)*rrj(m) + m*(m-1)*(m-2)*rri(m-3)*rrj(l+m))
                  p2iij=((l+m)*(l+m-1)*m*rri(l+m-2)*rrj(m-1)     + m*(m-1)*(l+m)*rri(m-2)*rrj(l+m-1))
                  p2ijj=((l+m)*rri(l+m-1)*m*(m-1)*rrj(m-2)       + m*(l+m)*(l+m-1)*rri(m-1)*rrj(l+m-2))
                  p2jjj=((l+m)*(l+m-1)*(l+m-2)*rrj(l+m-3)*rri(m) + m*(m-1)*(m-2)*rrj(m-3)*rri(l+m))

                  fij=fij+c(ll,it,iwf)*p1*p2ij
                  fuuu=fuuu+c(ll,it,iwf)*p1uuu*p2
                  fuui=fuui+c(ll,it,iwf)*p1uu*p2i
                  fuuj=fuuj+c(ll,it,iwf)*p1uu*p2j
                  fuii=fuii+c(ll,it,iwf)*p1u*p2ii
                  fuij=fuij+c(ll,it,iwf)*p1u*p2ij
                  fujj=fujj+c(ll,it,iwf)*p1u*p2jj
                  fiii=fiii+c(ll,it,iwf)*p1*p2iii
                  fiij=fiij+c(ll,it,iwf)*p1*p2iij
                  fijj=fijj+c(ll,it,iwf)*p1*p2ijj
                  fjjj=fjjj+c(ll,it,iwf)*p1*p2jjj

                endif

! derivatives of wave function wrt c-parameters
! ideriv = 0 parameter is not varied and is not dependent
!        = 1 parameter is a dependent parameter
!        = 2 parameter is an independent parameter that is varied
                ideriv=0
                if(nparmj.gt.0) then
!                  jparm_tempacm = jparm
!                  if (jparm.gt.nparmc(1)) then
!                    write(6,'(''Error: jparm too big!!'', i4)') jparm
!                    jparm = 1
!                  endif
                  if(jparm.le.nparmc(it)) then
                    if(ll.eq.iwjasc(jparm,it)) then
                      ideriv=2
                     elseif(isc.lt.12) then
                      do id=1,2*(nordc-1)           !   dowhile loop would be more efficient here?
                        if(ll.eq.iwc4(id)) then
                          jj=id
                          if(nvdepend(jj,it).gt.0) ideriv=1
                        endif
                      enddo
                    endif
                   elseif(isc.lt.12) then
                    do id=1,2*(nordc-1)           !   dowhile loop would be more efficient here?
                      if(ll.eq.iwc4(id)) then
                        jj=id
                        if(nvdepend(jj,it).gt.0) ideriv=1
                      endif
                    enddo
                  endif

!                 if(ll.eq.iwjasc(jparm,it)) then
!                   ideriv=2
!                  else
!                   do 31 id=1,2*(nordc-1)           !   dowhile loop would be more efficient here?
!                     if(ll.eq.iwc4(id)) then
!                       jj=id
!                       if(nvdepend(jj,it).gt.0) ideriv=1
!                     endif
!  31               continue
!                 endif ! ll
!c                 jparm = jparm_tempacm
                endif ! nparmj

                if(ideriv.gt.0) then
                  gp=pc
                  gu=pu
                  guu=puu
                  gi=ppi
                  gii=pii
                  gj=pj
                  gjj=pjj
                  gui=pui
                  guj=puj

                  guu=guu*dd1*dd1+gu*dd2
                  gu=gu*dd1/rij

                  gui=gui*dd1*dd7
                  guj=guj*dd1*dd8

                  gii=gii*dd7*dd7+gi*dd9
                  gjj=gjj*dd8*dd8+gj*dd10
                  gi=gi*dd7/ri
                  gj=gj*dd8/rj

!!!!  een for periodic systems         WAS
                  if(icutjasc .gt. 0 .or. iperiodic .ne. 0) then

                     guu = guu * fcut
                     gii = gii * fcut +(2 * gi * ri * dfcuti + gp * d2fcuti)*fcutj
                     gi = gi * fcut + (gp * fcutj *  dfcuti)/ri
                     gui = gui * fcut + (gu * fcutj *  dfcuti*rij)

                     gjj = gjj * fcut + (2 * gj * dfcutj *rj + gp * d2fcutj)*fcuti
                     gj = gj * fcut + (gp * fcuti *  dfcutj)/rj
                     guj = guj * fcut + (gu * fcuti *  dfcutj * rij)
                     gp = gp * fcut
                     gu = gu * fcut

                  endif
!!! end WAS

                  if(ideriv.eq.1) then

                    do id=1,nvdepend(jj,it)  ! used to be labeled 33

                      iparm=npoint(it)+iwdepend(jj,id,it)+nparms
                      cd=cdep(jj,id,it)

                      go(i,j,iparm)=go(i,j,iparm)+cd*gp
                      gvalue(iparm)=gvalue(iparm)+cd*gp
!       if we have an infinite wire, then for the en and een terms, we only
!          use the distance from the electron to the center of the wire
!          (for the first center, anyway)
!          thus, derivatives only depend on en distance in the y-direction
                      if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then
                        g(1,i,iparm)=g(1,i,iparm)+cd*(gu*rvec_ee(1,ij))
                        g(2,i,iparm)=g(2,i,iparm)+cd*(gi*rvec_en(2,i,ic)+gu*rvec_ee(2,ij))
                        g(3,i,iparm)=g(3,i,iparm)+cd*(gu*rvec_ee(3,ij))
                        g(1,j,iparm)=g(1,j,iparm)+cd*(-gu*rvec_ee(1,ij))
                        g(2,j,iparm)=g(2,j,iparm)+cd*(gj*rvec_en(2,j,ic)-gu*rvec_ee(2,ij))
                        g(3,j,iparm)=g(3,j,iparm)+cd*(-gu*rvec_ee(3,ij))
                      else
                        g(1,i,iparm)=g(1,i,iparm)+cd*(gi*rvec_en(1,i,ic)+gu*rvec_ee(1,ij))
                        g(2,i,iparm)=g(2,i,iparm)+cd*(gi*rvec_en(2,i,ic)+gu*rvec_ee(2,ij))
                        g(3,i,iparm)=g(3,i,iparm)+cd*(gi*rvec_en(3,i,ic)+gu*rvec_ee(3,ij))
                        g(1,j,iparm)=g(1,j,iparm)+cd*(gj*rvec_en(1,j,ic)-gu*rvec_ee(1,ij))
                        g(2,j,iparm)=g(2,j,iparm)+cd*(gj*rvec_en(2,j,ic)-gu*rvec_ee(2,ij))
                        g(3,j,iparm)=g(3,j,iparm)+cd*(gj*rvec_en(3,j,ic)-gu*rvec_ee(3,ij))
                      endif
!      This equation (and the subsequent u,s,t notation) comes from
!        eqn 5 of Pekeris, Phys Rev., 112, 1649 (1958), which
!        is derived in eqns. 3-5 of Hylleraas, Z. Physik 54, 347 (1929)
!      The expression for wires, where /psi = /psi(y_1, y_2, r_12) rather than
!        /psi(r_1, r_2, r_12) follows from the same type of calculation (ACM)
                      if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then ! ri = yi
                         d2g(iparm)=d2g(iparm) + cd*((ndim- 1.)*2.*gu &
     &                   + 2.*guu + gii + gjj + 2.*gui*(ri-rj)/rij + 2.*guj*(rj-ri)/rij)
                      else
                         d2g(iparm)=d2g(iparm) + cd*((ndim-1)*(2*gu+gi+gj) &
     &                   + 2*guu + gii +  gjj + gui*u2pst/(ri*rij) + guj*u2mst/(rj*rij))
                      endif
!  33                 d2g(iparm)=d2g(iparm) + cd*(2*(guu + 2*gu)
!    &                + gui*u2pst/(ri*rij) + guj*u2mst/(rj*rij)
!    &                + gii + 2*gi + gjj + 2*gj)

                    enddo        ! loop over id.  Used to be labeled 33.
!                   jj=jj+1



                    if(igradhess.gt.0 .and. nparms.eq.1) then
                      didk(iparm)=didk(iparm)+cd*(pu*dkij+ppi*dki+pj*dkj)
                    endif

                   elseif(ideriv.eq.2) then   ! independent parameters

                    iparm=npoint(it)+jparm+nparms

                    go(i,j,iparm)=go(i,j,iparm)+gp
                    gvalue(iparm)=gvalue(iparm)+gp
!       if we have an infinite wire, then for the en and een terms, we only
!          use the distance from the electron to the center of the wire
!          (for the first center, anyway)
!          thus, derivatives only depend on en distance in the y-direction
                    if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then
                      g(1,i,iparm)=g(1,i,iparm)+gu*rvec_ee(1,ij)
                      g(2,i,iparm)=g(2,i,iparm)+gi*rvec_en(2,i,ic)+gu*rvec_ee(2,ij)
                      g(3,i,iparm)=g(3,i,iparm)+gu*rvec_ee(3,ij)
                      g(1,j,iparm)=g(1,j,iparm)-gu*rvec_ee(1,ij)
                      g(2,j,iparm)=g(2,j,iparm)+gj*rvec_en(2,j,ic)-gu*rvec_ee(2,ij)
                      g(3,j,iparm)=g(3,j,iparm)-gu*rvec_ee(3,ij)
                    else
                      g(1,i,iparm)=g(1,i,iparm)+gi*rvec_en(1,i,ic)+gu*rvec_ee(1,ij)
                      g(2,i,iparm)=g(2,i,iparm)+gi*rvec_en(2,i,ic)+gu*rvec_ee(2,ij)
                      g(3,i,iparm)=g(3,i,iparm)+gi*rvec_en(3,i,ic)+gu*rvec_ee(3,ij)
                      g(1,j,iparm)=g(1,j,iparm)+gj*rvec_en(1,j,ic)-gu*rvec_ee(1,ij)
                      g(2,j,iparm)=g(2,j,iparm)+gj*rvec_en(2,j,ic)-gu*rvec_ee(2,ij)
                      g(3,j,iparm)=g(3,j,iparm)+gj*rvec_en(3,j,ic)-gu*rvec_ee(3,ij)
                    endif

                    if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then ! ri = yi
                       d2g(iparm)=d2g(iparm) + (ndim- 1.)*2.*gu &
     &                   + 2.*guu + gii + gjj + 2.*gui*(ri-rj)/rij + 2.*guj*(rj-ri)/rij
                    else
                       d2g(iparm)=d2g(iparm) + (ndim-1)*(2*gu+gi+gj) &
     &                   + 2*guu + gii +  gjj + gui*u2pst/(ri*rij) + guj*u2mst/(rj*rij)
                    endif
!                   d2g(iparm)=d2g(iparm) + 2*(guu + 2*gu)
!    &              + gui*u2pst/(ri*rij) + guj*u2mst/(rj*rij)
!    &              + gii + 2*gi + gjj + 2*gj

                    jparm=jparm+1

                    if(igradhess.gt.0 .and. nparms.eq.1) then
                      didk(iparm)=didk(iparm)+pu*dkij+ppi*dki+pj*dkj
                    endif

                  endif
!               write(6,'(''i,j,iparm,go(i,j,iparm),gvalue(iparm),(g(k,i,iparm),g(k,j,iparm),k=1,3)'',3i5,12d12.4)')
!    &          i,j,iparm,go(i,j,iparm),gvalue(iparm),(g(kk,i,iparm),g(kk,j,iparm),kk=1,3)

                endif
              endif
   55   continue

! derivatives (go,gvalue and g) wrt scalek parameter
        if(nparms.eq.1) then

          iparm=1

          gp=fu*dkij + fi*dki + fj*dkj
          gu=(dkij*fuu*dd1 + fu*drij + dki*fui*dd1 + dkj*fuj*dd1)/rij
          gi=(dkij*fui*dd7 + dki*fii*dd7 + fi*dri + dkj*fij*dd7)/ri
          gj=(dkij*fuj*dd8 + dkj*fjj*dd8 + fj*drj + dki*fij*dd8)/rj

          go(i,j,iparm)=go(i,j,iparm) + gp
          gvalue(iparm)=gvalue(iparm) + gp
!       if we have an infinite wire, then for the en and een terms, we only
!          use the distance from the electron to the center of the wire
!          (for the first center, anyway)
!          thus, derivatives only depend on en distance in the y-direction
          if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then
            g(1,i,iparm)=g(1,i,iparm) + gu*rvec_ee(1,ij)
            g(2,i,iparm)=g(2,i,iparm) + gi*rvec_en(2,i,ic) + gu*rvec_ee(2,ij)
            g(3,i,iparm)=g(3,i,iparm) + gu*rvec_ee(3,ij)
            g(1,j,iparm)=g(1,j,iparm) - gu*rvec_ee(1,ij)
            g(2,j,iparm)=g(2,j,iparm) + gj*rvec_en(2,j,ic) - gu*rvec_ee(2,ij)
            g(3,j,iparm)=g(3,j,iparm) - gu*rvec_ee(3,ij)
          else
            g(1,i,iparm)=g(1,i,iparm) + gi*rvec_en(1,i,ic) + gu*rvec_ee(1,ij)
            g(2,i,iparm)=g(2,i,iparm) + gi*rvec_en(2,i,ic) + gu*rvec_ee(2,ij)
            g(3,i,iparm)=g(3,i,iparm) + gi*rvec_en(3,i,ic) + gu*rvec_ee(3,ij)
            g(1,j,iparm)=g(1,j,iparm) + gj*rvec_en(1,j,ic) - gu*rvec_ee(1,ij)
            g(2,j,iparm)=g(2,j,iparm) + gj*rvec_en(2,j,ic) - gu*rvec_ee(2,ij)
            g(3,j,iparm)=g(3,j,iparm) + gj*rvec_en(3,j,ic) - gu*rvec_ee(3,ij)
          endif

          gui=dkij*fuui*dd1*dd7 + drij*fui*dd7 + dri*fui*dd1 + dki*fuii*dd1*dd7 + dkj*fuij*dd1*dd7
          guj=dkij*fuuj*dd1*dd8 + drij*fuj*dd8 + drj*fuj*dd1 + dkj*fujj*dd1*dd8 + dki*fuij*dd1*dd8
          gtu=dd2*(fuu*dkij + fui*dki + fuj*dkj) + 2*fuu*dd1*drij + fu*dr2ij &
     &      + dd1*dd1*(fuuu*dkij + fuui*dki + fuuj*dkj)
          gti=dd9*(fui*dkij + fii*dki + fij*dkj) + fi*dr2i + 2*fii*dd7*dri &
     &      + dd7*dd7*(fuii*dkij + fiii*dki + fiij*dkj)
          gtj=dd10*(fuj*dkij + fjj*dkj + fij*dki) + fj*dr2j + 2*fjj*dd8*drj &
     &       + dd8*dd8*(fujj*dkij + fjjj*dkj + fijj*dki)

!        check to see what gtu and gti are!
          if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then ! ri = yi
             d2g(iparm)=d2g(iparm) + (ndim- 1.)*2.*gu + 2.*gui*(ri-rj)/rij + 2.*guj*(rj-ri)/rij &
     &          + 2.*gtu + gti + gtj
          else
             d2g(iparm)=d2g(iparm) + (2*gu+gi+gj)*ndim1 + gui*u2pst/(ri*rij) + guj*u2mst/(rj*rij) &
     &          + 2*gtu + gti + gtj
          endif

          if(igradhess.gt.0 .and. nparms.eq.1) then
            didk(iparm)=didk(iparm)+(fuu*dkij+fui*dki+fuj*dkj)*dkij+fu*dk2ij &
     &                             +(fui*dkij+fii*dki+fij*dkj)*dki+fi*dk2i &
     &                             +(fuj*dkij+fij*dki+fjj*dkj)*dkj+fj*dk2j
          endif

        endif

        if(ifock.gt.0) call fock(uu(1),ss(1),tt(1),rri(1),rrj(1),it)

        fuu=fuu*dd1*dd1+fu*dd2
        fu=fu*dd1/rij

        fui=fui*dd1*dd7
        fuj=fuj*dd1*dd8

        fii=fii*dd7*dd7+fi*dd9
        fjj=fjj*dd8*dd8+fj*dd10
        fi=fi*dd7/ri
        fj=fj*dd8/rj


!!!!  een for periodic systems         WAS
       if(icutjasc .gt. 0 .or. iperiodic .ne. 0) then

           fuu = fuu * fcut
           fii = fii * fcut +(2 * fi * ri * dfcuti + fc * d2fcuti)*fcutj
           fi = fi * fcut + (fc * fcutj *  dfcuti)/ri
           fui = fui * fcut + (fu * fcutj *  dfcuti*rij)

           fjj = fjj * fcut + (2 * fj * dfcutj *rj + fc * d2fcutj)*fcuti
           fj = fj * fcut + (fc * fcuti *  dfcutj)/rj
           fuj = fuj * fcut + (fu * fcuti *  dfcutj * rij)
           fc = fc * fcut
           fu = fu * fcut

        endif
!!!! end WAS

        fso(i,j)=fso(i,j) + fc


!       if we have an infinite wire, then for the en and een terms, we only
!          use the distance from the electron to the center of the wire
!          (for the first center, anyway)
!          thus, derivatives only depend on en distance in the y-direction
        if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then
          fijo(1,i,j)=fijo(1,i,j) + fu*rvec_ee(1,ij)
          fijo(2,i,j)=fijo(2,i,j) + fi*rvec_en(2,i,ic)+fu*rvec_ee(2,ij)
          fijo(3,i,j)=fijo(3,i,j) + fu*rvec_ee(3,ij)
          fijo(1,j,i)=fijo(1,j,i) - fu*rvec_ee(1,ij)
          fijo(2,j,i)=fijo(2,j,i) + fj*rvec_en(2,j,ic)-fu*rvec_ee(2,ij)
          fijo(3,j,i)=fijo(3,j,i) - fu*rvec_ee(3,ij)
        else
          fijo(1,i,j)=fijo(1,i,j) + fi*rvec_en(1,i,ic)+fu*rvec_ee(1,ij)
          fijo(2,i,j)=fijo(2,i,j) + fi*rvec_en(2,i,ic)+fu*rvec_ee(2,ij)
          fijo(3,i,j)=fijo(3,i,j) + fi*rvec_en(3,i,ic)+fu*rvec_ee(3,ij)
          fijo(1,j,i)=fijo(1,j,i) + fj*rvec_en(1,j,ic)-fu*rvec_ee(1,ij)
          fijo(2,j,i)=fijo(2,j,i) + fj*rvec_en(2,j,ic)-fu*rvec_ee(2,ij)
          fijo(3,j,i)=fijo(3,j,i) + fj*rvec_en(3,j,ic)-fu*rvec_ee(3,ij)
        endif
!       write(6,'(''i,j,fijo2='',2i5,9d12.4)') i,j,(fijo(k,i,j),k=1,ndim)

!       d2ijo(i,j)=d2ijo(i,j) + 2*(fuu + 2*fu) + fui*u2pst/(ri*rij)
!    &  + fuj*u2mst/(rj*rij) + fii + 2*fi + fjj + 2*fj

!      This equation (and the subsequent u,s,t notation) comes from
!        eqn 5 of Pekeris, Phys Rev., 112, 1649 (1958), which
!        is derived in eqns. 3-5 of Hylleraas, Z. Physik 54, 347 (1929)
!      The expression for wires, where /psi = /psi(y_1, y_2, r_12) rather than
!        /psi(r_1, r_2, r_12) follows from the same type of calculation (ACM)
        if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then ! ri = yi
           d2ijo(i,j)=d2ijo(i,j) + ndim1*2.*fu &
     &          + 2.*fuu + fii + fjj + 2.*fui*(ri-rj)/rij + 2.*fuj*(rj-ri)/rij
        else  ! Pekeris, Phys Rev 112, 1649 (1958) eqn 5:
           d2ijo(i,j)=d2ijo(i,j) + ndim1*(2*fu+fi+fj) &
     &          + 2*fuu + fii +  fjj + fui*u2pst/(ri*rij) + fuj*u2mst/(rj*rij)
        endif

!       v(1,i)=v(1,i) + fi*rvec_en(1,i,ic)+fu*rvec_ee(1,ij)
!       v(2,i)=v(2,i) + fi*rvec_en(2,i,ic)+fu*rvec_ee(2,ij)
!       v(3,i)=v(3,i) + fi*rvec_en(3,i,ic)+fu*rvec_ee(3,ij)
!       v(1,j)=v(1,j) + fj*rvec_en(1,j,ic)-fu*rvec_ee(1,ij)
!       v(2,j)=v(2,j) + fj*rvec_en(2,j,ic)-fu*rvec_ee(2,ij)
!       v(3,j)=v(3,j) + fj*rvec_en(3,j,ic)-fu*rvec_ee(3,ij)

!       d2 = d2 + ndim1*(2*fu+fi+fj)
!    &  + 2*fuu + fii +  fjj + fui*u2pst/(ri*rij) + fuj*u2mst/(rj*rij)

!c      d2 = d2 + 2*(fuu + 2*fu) + fui*u2pst/(ri*rij)
!c   &  + fuj*u2mst/(rj*rij) + fii + 2*fi + fjj + 2*fj

   57 continue

   58 fsum=fsum+fso(i,j)
      v(1,i)=v(1,i)+fijo(1,i,j)
      v(2,i)=v(2,i)+fijo(2,i,j)
      v(3,i)=v(3,i)+fijo(3,i,j)
      v(1,j)=v(1,j)+fijo(1,j,i)
      v(2,j)=v(2,j)+fijo(2,j,i)
      v(3,j)=v(3,j)+fijo(3,j,i)
!  write(6,'(''v='',2i2,9d12.4)') i,j,(v(k,i),v(k,j),k=1,3)
!     div_vj(i)=div_vj(i)+d2ijo(i,j)/2
!     div_vj(j)=div_vj(j)+d2ijo(i,j)/2
   60 d2=d2+d2ijo(i,j)
!     write(6,'(''fsum,d2='',9d12.4)') fsum,d2

! e-n terms
   65 do 90 i=1,nelec

        fso(i,i)=0
        fijo(1,i,i)=0
        fijo(2,i,i)=0
        fijo(3,i,i)=0
        d2ijo(i,i)=0

        do 66 iparm=1,nparmj+nparms
   66     go(i,i,iparm)=zero

        do 80 ic=1,ncent
          it=iwctype(ic)

!       if we have an infinite wire, then for the en and een terms, for ic=1,
!         we only use the distance from the electron to the y-axis of the wire
          if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then
             ri=abs(rvec_en(2,i,ic)) ! y-component of rvec_en is dist to wire center
          else
             ri=r_en(i,ic)
          endif

          if(ri.gt.cutjas_en) goto 80

          call scale_dist2(ri,rri(1),dd7,dd9,1)
          if(nparms.eq.1) call deriv_scale(ri,dk,dk2,dr,dr2,1,iderivk)

          top=a4(1,it,iwf)*rri(1)
          topi=a4(1,it,iwf)
          topii=0

          bot=1+a4(2,it,iwf)*rri(1)
          boti=a4(2,it,iwf)
          botii=0
          bot2=bot*bot

!          feni=topi/bot-boti*top/bot2
!          fenii=topii-(botii*top+2*boti*topi)/bot+2*boti**2*top/bot2
!          fenii=fenii/bot
! simpler expressions are :
          fen=top/bot
          feni=topi/bot2
          fenii=-2*feni*boti/bot
          tempii=fenii
          if(isc.eq.8 .or. isc.eq.10) then
            fen=fen/scalek(iwf)
            feni=feni/scalek(iwf)
            fenii=fenii/scalek(iwf)
          endif
          fen=fen-asymp_jasa(it,iwf)

          do 70 iord=2,norda
            rri(iord)=rri(1)*rri(iord-1)
            fen=fen+a4(iord+1,it,iwf)*rri(iord)
            feni=feni+a4(iord+1,it,iwf)*iord*rri(iord-1)
   70       fenii=fenii+a4(iord+1,it,iwf)*iord*(iord-1)*rri(iord-2)

! for scale derivatives we also need feniii:
          if(nparms.eq.1) then
            if(isc.eq.8 .or. isc.eq.10) then
              stop 'scalek opt not fully implemented for isc=8,10'
            endif
            feniii=-3*tempii*boti/bot
            do 73 iord=3,norda
   73         feniii=feniii+a4(iord+1,it,iwf)*iord*(iord-1)*(iord-2)*rri(iord-3)
          endif

          tempii=fenii*dd7*dd7+feni*dd9
          tempi=feni*dd7/ri

          fso(i,i)=fso(i,i)+fen
!       if we have an infinite wire, then for the en and een terms, we only
!          use the distance from the electron to the center of the wire
!          (for the first center, anyway)
!          thus, derivatives only depend on en distance in the y-direction
          if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then
            fijo(2,i,i)=fijo(2,i,i) + tempi*rvec_en(2,i,ic)
            d2ijo(i,i) = d2ijo(i,i) + tempii
          else
            fijo(1,i,i)=fijo(1,i,i) + tempi*rvec_en(1,i,ic)
            fijo(2,i,i)=fijo(2,i,i) + tempi*rvec_en(2,i,ic)
            fijo(3,i,i)=fijo(3,i,i) + tempi*rvec_en(3,i,ic)
            d2ijo(i,i) = d2ijo(i,i) + tempii + ndim1*tempi
          endif
!         write(6,'(''fijo='',9d12.4)') (fijo(k,i,i),k=1,ndim),feni,rvec_en(1,i,ic)


!         v(1,i)=v(1,i) + feni*rvec_en(1,i,ic)
!         v(2,i)=v(2,i) + feni*rvec_en(2,i,ic)
!         v(3,i)=v(3,i) + feni*rvec_en(3,i,ic)

!         d2 = d2 + fenii + ndim1*feni

          do 78 jparm=1,nparma(it)
            iparm=npointa(it)+jparm+nparms

            if(iwjasa(jparm,it).eq.1) then
              top=rri(1)
              topi=one
              topii=zero

              bot=one+a4(2,it,iwf)*rri(1)
              boti=a4(2,it,iwf)
              botii=zero
              bot2=bot*bot

              botasymp=1+a4(2,it,iwf)*asymp_r_en(iwf)

              gen=top/bot-asymp_r_en(iwf)/botasymp
!              geni=topi/bot-boti*top/bot2
!              genii=topii-(botii*top+2*boti*topi)/bot+2*boti**2*top/bot2
!              genii=genii/bot
              geni=topi/bot2
              genii=-2*boti*geni/bot
              if(isc.eq.8 .or. isc.eq.10) then
                gen=gen/scalek(iwf)
                geni=geni/scalek(iwf)
                genii=genii/scalek(iwf)
              endif

              if(igradhess.gt.0 .and. nparms.eq.1) then
                if(isc.eq.8 .or. isc.eq.10) then
                  stop 'scalek opt not fully implemented for isc=8,10'
                endif
                asympterm=dasymp_r_en(iwf)/(botasymp*botasymp)
!                asympterm=0
                didk(iparm)=didk(iparm)+geni*dk-asympterm
              endif

             elseif(iwjasa(jparm,it).eq.2) then
              top=-a4(1,it,iwf)*rri(1)*rri(1)
              topi=-2*a4(1,it,iwf)*rri(1)
              topii=-2*a4(1,it,iwf)

              bot0=one+a4(2,it,iwf)*rri(1)
              bot=bot0*bot0
              boti=2*bot0*a4(2,it,iwf)
              botii=2*a4(2,it,iwf)*a4(2,it,iwf)
              bot2=bot*bot

              botasymp=1+a4(2,it,iwf)*asymp_r_en(iwf)
              botasymp2=botasymp*botasymp

              gen=top/bot+a4(1,it,iwf)*asymp_r_en(iwf)**2/botasymp2
!             geni=topi/bot-boti*top/bot2
!             genii=topii-(botii*top+2*boti*topi)/bot+2*boti**2*top/bot2
!             genii=genii/bot
              geni=topi/(bot*bot0)
              genii=topii*(1-2*a4(2,it,iwf)*rri(1))/bot2
              if(isc.eq.8 .or. isc.eq.10) then
                gen=gen/scalek(iwf)
                geni=geni/scalek(iwf)
                genii=genii/scalek(iwf)
              endif

              if(igradhess.gt.0 .or. l_opt_jas_2nd_deriv) then
                d2d2a(it)=d2d2a(it)-2*top*rri(1)/bot/bot0-2*a4(1,it,iwf)*asymp_r_en(iwf)**3/(1+a4(2,it,iwf)*asymp_r_en(iwf))**3
                d1d2a(it)=d1d2a(it)-rri(1)*rri(1)/bot+asymp_r_en(iwf)**2/(1+a4(2,it,iwf)*asymp_r_en(iwf))**2
                if(isc.eq.8 .or. isc.eq.10) then
                  d2d2a(it)=d2d2a(it)/scalek(iwf)
                  d1d2a(it)=d1d2a(it)/scalek(iwf)
                endif
                if(ipr.ge.1) &
     & write(6,'(''it,rri(1),a4(1,it,iwf),asymp_r_en(iwf),a4(2,it,iwf),top,bot,bot0,d1d2a(it),d2d2a(it)'',i2,20d12.4)') &
     & it,rri(1),a4(1,it,iwf),asymp_r_en(iwf),a4(2,it,iwf),top,bot,bot0,d1d2a(it),d2d2a(it)
                if(nparms.eq.1) then
                  if(isc.eq.8 .or. isc.eq.10) then
                    stop 'scalek opt not fully implemented for isc=8,10'
                  endif
                  asympterm=topii*asymp_r_en(iwf)/(botasymp*botasymp2)*dasymp_r_en(iwf)
!                  asympterm=0
                  didk(iparm)=didk(iparm)+geni*dk-asympterm
                endif
              endif

             else
              iord=iwjasa(jparm,it)-1
              asympiord=asymp_r_en(iwf)**iord
              gen=rri(iord)-asympiord
              geni=iord*rri(iord-1)
              genii=iord*(iord-1)*rri(iord-2)
              if(nparms.eq.1 .and. igradhess.gt.0) then
                asympterm=asympiord/asymp_r_en(iwf)*dasymp_r_en(iwf)
!                asympterm=0
                didk(iparm)=didk(iparm)+iord*(rri(iord-1)*dk-asympterm)
              endif
            endif

            genii=genii*dd7*dd7+geni*dd9
!            geni=geni*dd7/r_en(i,ic)
!           Changed above line to avoid 'if iperiodic=1 and nloc=-4?' statement
            geni=geni*dd7/ri      ! ACM - I think this is equivalent

            go(i,i,iparm)=go(i,i,iparm)+gen
            gvalue(iparm)=gvalue(iparm)+gen

!       if we have an infinite wire, then for the en and een terms, we only
!          use the distance from the electron to the center of the wire
!          (for the first center, anyway)
!          thus, derivatives only depend on en distance in the y-direction
            if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then
              g(2,i,iparm)=g(2,i,iparm)+geni*rvec_en(2,i,ic)
              d2g(iparm)=d2g(iparm)+genii
            else
              g(1,i,iparm)=g(1,i,iparm)+geni*rvec_en(1,i,ic)
              g(2,i,iparm)=g(2,i,iparm)+geni*rvec_en(2,i,ic)
              g(3,i,iparm)=g(3,i,iparm)+geni*rvec_en(3,i,ic)
              d2g(iparm)=d2g(iparm)+genii+ndim1*geni
            endif
!  Put this line in the above if...else block (ACM):
!   78       d2g(iparm)=d2g(iparm)+genii+ndim1*geni
  78        continue

! derivatives (go,gvalue and g) wrt scalek parameter
          if(nparms.eq.1) then
            if(isc.eq.8 .or. isc.eq.10) then
              stop 'scalek opt not fully implemented for isc=8,10'
            endif

            iparm=1
!            call deriv_scale(ri,dk,dk2,dr,dr2,1,iderivk)

            gen=feni*dk-dasymp_jasa(it,iwf)*dasymp_r_en(iwf)
            geni=(fenii*dk*dd7+feni*dr)/ri
            genii=fenii*dk*dd9+(feniii*dk*dd7+2*fenii*dr)*dd7+feni*dr2

            go(i,i,iparm)=go(i,i,iparm)+gen
            gvalue(iparm)=gvalue(iparm)+gen

!       if we have an infinite wire, then for the en and een terms, we only
!          use the distance from the electron to the center of the wire
!          (for the first center, anyway)
!          thus, derivatives only depend on en distance in the y-direction
            if((iperiodic.eq.1).and.(nloc.eq.-4).and.(ic.eq.1)) then
              g(2,i,iparm)=g(2,i,iparm) + geni*rvec_en(2,i,ic)
              d2g(iparm)=d2g(iparm) + genii
            else
              g(1,i,iparm)=g(1,i,iparm) + geni*rvec_en(1,i,ic)
              g(2,i,iparm)=g(2,i,iparm) + geni*rvec_en(2,i,ic)
              g(3,i,iparm)=g(3,i,iparm) + geni*rvec_en(3,i,ic)
              d2g(iparm)=d2g(iparm) + genii+ndim1*geni
            endif

!       Placed this line in the above if...else block (ACM):
!            d2g(iparm)=d2g(iparm) + genii+ndim1*geni

            if(igradhess.gt.0) then
              didk(1)=didk(1)+fenii*dk*dk+feni*dk2 &
     &-d2asymp_jasa(it,iwf)*dasymp_r_en(iwf)*dasymp_r_en(iwf)-dasymp_jasa(it,iwf)*d2asymp_r_en(iwf)
            endif

          endif

   80     continue

        fsum=fsum+fso(i,i)
        v(1,i)=v(1,i)+fijo(1,i,i)
        v(2,i)=v(2,i)+fijo(2,i,i)
        v(3,i)=v(3,i)+fijo(3,i,i)
!       write(6,'(''v='',9d12.4)') (v(k,i),k=1,ndim)
!       div_vj(i)=div_vj(i)+d2ijo(i,i)
   90   d2=d2+d2ijo(i,i)

      if(ijas.eq.6) then
        term=1/(c1_jas6_en(iwf)*scalek(iwf))
        fsum=term*fsum
        d2=term*d2
        do 100 i=1,nelec
!         div_vj(i)=term*div_vj(i)
          do 95 k=1,ndim
   95       v(k,i)=term*v(k,i)
          do 100 j=1,nelec
            d2ijo(i,j)=term*d2ijo(i,j)
            do 100 k=1,ndim
  100         fijo(k,i,j)=term*fijo(k,i,j)
      endif

      fsumo=fsum
      d2o=d2
      do 110 i=1,nelec
        fjo(1,i)=v(1,i)
        fjo(2,i)=v(2,i)
  110   fjo(3,i)=v(3,i)

      value=fsum

      call object_modified_by_index (gvalue_index) !JT
      call object_modified_by_index (g_index) !JT

      if (l_opt_jas_2nd_deriv) then
       call object_modified_by_index (d2d2a_index) !JT
       call object_modified_by_index (d1d2a_index) !JT
       call object_modified_by_index (d1d2b_index) !JT
       call object_modified_by_index (d2d2b_index) !JT
      endif

      return
      end
