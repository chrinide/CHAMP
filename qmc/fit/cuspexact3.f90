      subroutine cuspexact3(iprin)
! Written by Claudia Filippi

      use constants_mod
      use atom_mod
      use contr2_mod
      use jaspar3_mod
      use cuspmat_mod
      implicit real*8(a-h,o-z)

      dimension o(2*nord),op(0:2*nord)
      dimension bm(neqs),xn(neqs)

      nvar=neqs

      do 200 it=1,nctype

      do 10 ii=1,nvar
  10    bm(ii)=zero
      do 20 jp=1,nord
        o(jp+nord)=zero
        op(jp+nord-1)=zero
        o(jp)=zero
  20    op(jp-1)=zero

      jj=1
      ll=0
      do 30 jp=1,nord
        jpsh=jp+nord
        do 30 ju=jp,0,-1
          jsx=jp-ju
          do 30 js=jsx,0,-1
            ll=ll+1
            jt=jsx-js
            jsg=1
            if(jj.le.nvar.and.ll.eq.iwc(jj)) then
              jj=jj+1
             else
              if(jt.eq.0) then
                if(ju.eq.0) o(jpsh)=o(jpsh)+c(ll,it,1)
                if(ju.eq.1) op(jpsh-1)=op(jpsh-1)+c(ll,it,1)
              endif
              if(mod(jt,2).ne.0) jsg=-1
              o(jp)=o(jp)+jsg*c(ll,it,1)
              op(jp-1)=op(jp-1)+jsg*(js-jt)*c(ll,it,1)
            endif
  30  continue

      if(ifock.gt.0) call fockexact3(o,op,it,ipr)

      do 40 jp=1,nord
        bm(jp+ishe)=-op(jp+nord-1)
  40    bm(jp)=-op(jp-1)

      if(iprin.eq.1) write(6,'(40f8.2)') (bm(jj),jj=1,nvar)

      do 60 i=1,nvar
        xn(i)=zero
        do 60 j=1,nvar
  60      xn(i)=xn(i)+cm(i,j)*bm(j)

      do 80 ii=1,nvar
  80    c(iwc(ii),it,1)=xn(ii)

 200  continue

      return
      end
