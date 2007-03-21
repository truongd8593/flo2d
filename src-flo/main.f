C------------------------------------------------------------------------------
C Main program of vertex-centroid scheme similar to Jameson, Frink
C------------------------------------------------------------------------------
      program main
      implicit none
      include 'param.h'
      integer          elem(3,ntmax), edge(2,nemax), tedge(2,nemax),
     +                 esue(3,ntmax), vedge(2,nemax), spts(nspmax),
     +                 bdedge(2,nbpmax), esubp(mesubp,nbpmax),
     +                 ptype(npmax)
      double precision coord(2,npmax), qc(nvar,ntmax), 
     +                 qcold(nvar,ntmax), dt(ntmax), af(3,npmax),
     +                 qv(nvar,npmax), carea(ntmax),
     +                 drmin(ntmax), res(nvar,ntmax), c1(nvar),
     +                 c2(nvar), c3(nvar)
      double precision cl, cd
      double precision qx(3,npmax), qy(3,npmax)

      integer          i, j, irk

      call math
      call read_input
      call geometric(elem, edge, tedge, esue, vedge, spts, ptype,
     +               bdedge, esubp, coord, drmin, carea, af)

C Set initial condition
      call initialize(qc, cl, cd)

      iter = 0
      fres = 1.0d20
      call system('rm -f FLO.RES')
      open(unit=99, file='FLO.RES')
      do while(iter .lt. MAXITER .and. fres .gt. MINRES)
c        call time_step(drmin, qc, dt)
         call time_step2(edge, tedge, carea, coord, qc, dt)
         call save_old(qc, qcold)

         do irk=1,nirk

C           Compute finite volume residual
            call fvresidual(elem, edge, tedge, vedge, spts, bdedge,
     +                      coord, qc, qv, qx, qy, af, carea, cl, cd, 
     +                      res)

C           Update the solution
            if(explicit .eq. yes)then
               do i=1,nt
                  call prim2con(qcold(1,i), c1)
                  call prim2con(qc(1,i),    c2)
                  do j=1,nvar
                     c3(j) = airk(irk)*c1(j) + 
     +                       birk(irk)*(c2(j)-dt(i)*res(j,i)/carea(i))
                  enddo
                  call con2prim(c3, qc(1,i))
               enddo
            else
               call lusgs(elem, esue, edge, tedge, coord, qcold, qc, 
     +                    res, dt, carea)
            endif

         enddo

         iter = iter + 1
         call residue(res)
         call clcd(edge, tedge, coord, qc, cl, cd)
         write(99,'(i6,4e16.6)') iter, fres, fresi, cl, cd
         if(mod(iter,saveinterval) .eq. 0)then
            call write_result(coord, elem, edge, qc, qv, cl, cd)
         endif

      enddo
      close(99)

      call write_result(coord, elem, edge, qc, qv, cl, cd)
      call write_sol(iter, fres, cl, cd)

      stop
      end
