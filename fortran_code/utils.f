C subroutines taken from the OSSOS Survey Simulator.
C Author:  Jean-Marc Petit (c 2022)

      subroutine RADECeclXV (pos, obspos, delta, ra, dec, ierr)

c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c This routine computes the RA and DEC of an object, defined by its
c barycentric ecliptic cartesian coordinates, with respect to an
c observatory, defined by its ICRF cartesian coordinates.
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c
c J-M. Petit  Observatoire de Besancon
c Version 1 : February 2004
c
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c INPUT
c     pos   : Object barycentric ecliptic cartsian coordinates (3*R8)
c     obspos: Observatory ICRF cartsian coordinates (3*R8)
c
c OUTPUT
c     delta : Distance to observatory (R8)
c     ra    : Right Ascension (R8)
c     dec   : Declination (R8)
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
Cf2py intent(in) pos
Cf2py intent(in) obspos
Cf2py intent(out) delta
Cf2py intent(out) ra
Cf2py intent(out) dec
Cf2py intent(out) ierr

      implicit none

      real(kind=8)
     $  obspos(3), ra, dec, pos(3), opos(3), delta

      integer(kind=4)
     $  ierr

c Compute ICRF cartesian coordinates
      call equat_ecl (-1, pos, opos, ierr)
      if ( ierr /= 0)  then
        return
      end if
c Compute RA and DEC
      opos(1) = opos(1) - obspos(1)
      opos(2) = opos(2) - obspos(2)
      opos(3) = opos(3) - obspos(3)
      call LatLong (opos, ra, dec, delta, ierr)

      return

      end

      subroutine LatLong (pos, long, lat, r, ierr)
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c This routine transforms cartesian coordinates into longitude,
c latitute and distance (almost spherical coordinates). If the input
c cordinates are in ICRF, then one obtains the RA and DEC
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c
c J-M. Petit  Observatoire de Besancon
c Version 1 : September 2003
c
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c INPUT
c     pos   : Object's cartesian coordinates
c
c OUTPUT
c     long  : Longitude (RA if ICRF)
c     lat   : Latitude (DEC if ICRF)
c     r     : Distance to center
c     ierr  : error code
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
Cf2py intent(in) pos
Cf2py intent(out) long
Cf2py intent(out) lat
Cf2py intent(out) r
Cf2py intent(out) ierr

      implicit none

      real(kind=8)
     $  pos(3), lat, long, r, Pi, TwoPi

      integer(kind=4) ierr

      parameter
     $  (Pi = 3.141592653589793238d0, TwoPi = 2.d0*Pi)

      r = dsqrt (pos(1)**2 + pos(2)**2 + pos(3)**2)
      long = datan2(pos(2), pos(1))
      if (long < 0.d0) long = long + TwoPi
      lat = asin(pos(3)/r)
      if ( ( long < 0 ) .or. (long > TwoPi) .or.
     $          (lat < -Pi/2) .or. (lat > Pi/2)) then
        ierr = 10
      end if
      return
      end


      subroutine ObsPos (code, t, pos, vel, r, ierr)

c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c This routine returns the cartesian coordinates of the observatory.
c Reference frame : ICRF
c Units : AU
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c
c J-M. Petit  Observatoire de Besancon
c Version 1 : September 2003
c
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c INPUT
c     code  : Observatory code (I4)
c              001 : GAIA
c              002 : Geocentric, Mignard's code
c              500 : Geocentric
c              -ve : file lun with trajectory (-ve value of)
c     t     : Time of observation (Julian day, not MJD) (R8)
c
c OUTPUT
c     pos   : Cartesian coordinates of observatory (AU) *(R8)
c     vel   : Cartesian velocity of observatory (AU) *(R8)
c     r     : Distance from observatory to Sun (AU) (R8)
c     ierr  : Error code (I4)
c                0 : nominal run
c               10 : unknown observatory code
c              100 : date of call earlier than xjdbeg
c              200 : date of call later   than xjdend

c Where pos/vel values are in AU
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
Cf2py intent(in) code
Cf2py intent(in) t
Cf2py intent(out) pos
Cf2py intent(out) vel
Cf2py intent(out) r
Cf2py intent(out) ierr

      implicit none

      integer(kind=4)
     $  code, ierr, istat, fun

      real(kind=8)
     $  pos(3), t, vel(3), km2AU, pos_b(3), vel_b(3), r, jd

      parameter
     $  (km2AU = 149597870.691d0)

      ierr = 0
      if (code == 1) then
         ierr = 10
         return
      else if (code == 2) then
         ierr = 10
         return
      else if (code == 500) then

c Get heliocentric position of Earth.
         call newcomb (t, pos)
         pos(1) = -pos(1)
         pos(2) = -pos(2)
         pos(3) = -pos(3)
         vel(1) = 0.d0
         vel(2) = 0.d0
         vel(3) = 0.d0
      else if ( code < 0 ) then
         fun = -1*code
         call read_jpl_csv(fun, t, pos, vel, ierr)
      else
         ierr = 10
         return
      end if

c Now move to barycenter. First get barycenter position (ecliptic).
      call BaryXV (t, pos_b, vel_b, istat)
      if (ierr /= 0) then
         write (6, *) 'Problem while getting barycenter position'
         return
      end if

c Convert barycenter position to Equatorial.
      call equat_ecl (-1, pos_b, pos_b, ierr)
      if (ierr /= 0) then
         write (6, *) 'Problem in conversion ecliptic -> equatorial'
         return
      end if
      call equat_ecl (-1, vel_b, vel_b, ierr)
      if (ierr /= 0) then
         write (6, *) 'Problem in conversion ecliptic -> equatorial'
         return
      end if
      pos(1) = pos(1) - pos_b(1)
      pos(2) = pos(2) - pos_b(2)
      pos(3) = pos(3) - pos_b(3)
      vel(1) = vel(1) - vel_b(1)
      vel(2) = vel(2) - vel_b(2)
      vel(3) = vel(3) - vel_b(3)


c Finally, computes distance from observatory to Sun.
      r = dsqrt((pos(1) + pos_b(1))**2 + (pos(2) + pos_b(2))**2
     $     + (pos(3) + pos_b(3))**2)

      end

c \subroutine{pos\_cart}

      subroutine pos_cart (a, ecc, inc, capo, smallo, capm,
     $  x, y, z)

c This routine transforms delaunay variables into cartisian
c variables, positions only.
c
c \subsection{Arguments}
c \subsubsection{Definitions}
c \begin{verse}
c \verb|a, e, inc, capo, smallo, capm| = osculating elements \\
c \verb|x, y, z| = cartesian variables: $X, Y, Z$
c \end{verse}
c
c \subsubsection{Declarations}
c
Cf2py intent(in) a
Cf2py intent(in) ecc
Cf2py intent(in) inc
Cf2py intent(in) capo
Cf2py intent(in) smallo
Cf2py intent(in) capm
Cf2py intent(out) x
Cf2py intent(out) y
Cf2py intent(out) z

      implicit none

      real(kind=8)
     $  a, ecc, inc, capo, smallo, capm, x, y, z

c \subsection{Variables}
c \subsubsection{Definitions}
c \begin{verse}
c \verb|cos_e, sin_e, cos_i, sin_i| = sinus and cosines of $E$ and
c      $i$ \\
c \verb|delau| = Delaunay variables: $l, \cos(g), \sin(g), \cos(h),
c      \sin(h), L, G, H$ \\
c \verb|e| = eccentric anomaly \\
c \verb|mat| = rotation matrix \\
c \verb|q_vec| = $q$ \\
c \end{verse}
c
c \subsubsection{Declarations}

      integer(kind=4)
     $  i

      real(kind=8)
     $  delau(8), cos_e, cos_i, e, mat(3,3), q_vec(2),
     $  sin_e, sin_i, signe, Pi, TwoPi, f, de, fp, fpp, fppp

      parameter
     $  (Pi = 3.141592653589793238d0, TwoPi = 2.d0*Pi)

c Computation of sinus and cosines of angles.

      signe = 1.d0
      if (a < 0.d0) signe = -1.d0
      cos_i = dcos(inc)
      sin_i = dsqrt(1.d0 - cos_i**2)
      delau(2) = dcos(smallo)
      delau(3) = dsin(smallo)
      delau(4) = dcos(capo)
      delau(5) = dsin(capo)
      delau(1) = capm - int(capm/TwoPi)*TwoPi
      delau(6) = signe*dsqrt(a*signe)
      delau(7) = abs(delau(6))*dsqrt((1.d0 - ecc**2)*signe)

c Rotation matrix.
c The rotation matrix is the composition of 3 matrices: $R_{xq} =
c  R_3(-h) \cdot R_1(-i) \cdot R_3(-g)$:
c \begin{displaymath}
c     R_{xq} = \left(\matrix{
c       \cos(h)\cos(g)-\frac{H}{G}\sin(h)\sin(g)&
c       -\cos(h)\sin(g)-\frac{H}{G}\sin(h)\cos(g)&
c       \sqrt{1-\frac{H^2}{G^2}}\sin(h) \cr
c       \sin(h)\cos(g)+\frac{H}{G}\cos(h)\sin(g)&
c       -\sin(h)\sin(g)+\frac{H}{G}\cos(h)\cos(g)&
c       -\sqrt{1-\frac{H^2}{G^2}}\cos(h) \cr
c       \sqrt{1-\frac{H^2}{G^2}}\sin(g)&
c       \sqrt{1-\frac{H^2}{G^2}}\cos(g)&
c       \frac{H}{G} \cr}\right);
c \end{displaymath}

      mat(1,1) = delau(4)*delau(2) - cos_i*delau(5)*delau(3)
      mat(1,2) = -delau(4)*delau(3) - cos_i*delau(5)*delau(2)
      mat(2,1) = delau(5)*delau(2) + cos_i*delau(4)*delau(3)
      mat(2,2) = -delau(5)*delau(3) + cos_i*delau(4)*delau(2)
      mat(3,1) = sin_i*delau(3)
      mat(3,2) = sin_i*delau(2)

c Eccentric anomaly.
c We solve iteratively the equation:
c \begin{displaymath}
c     E - e \sin(E) = l
c \end{displaymath}
c using the accelerated Newton's method (see Danby).

      e = delau(1) + sign(.85d0, dsin(delau(1)))*ecc
      i = 0

 1000 continue
      sin_e = ecc*dsin(e)
      f = e - sin_e - delau(1)
      if (dabs(f) > 1.d-14) then
         cos_e = ecc*dcos(e)
         fp = 1.d0 - cos_e
         fpp = sin_e
         fppp = cos_e
         de = -f/fp
         de = -f/(fp + de*fpp/2.d0)
         de = -f/(fp + de*fpp/2.d0 + de*de*fppp/6.d0)
         e = e + de
         i = i + 1
         if (i < 20) goto 1000
         write (6, *) 'POS_CART: No convergence: ', i, f
         write (6, *) e, de
         write (6, *) a, ecc, inc
         write (6, *) capo, smallo, capm
         stop
      end if

c Coordinates relative to the orbit.
c The cartisian coordinate are given by $\vec X = R_{xq} \vec q$
c and $\vec P = R_{xq} \dot{\vec q}$, where:
c \begin{eqnarray*}
c     \vec q & = & \left(\frac{L^2}{\mu}(\cos(E) - e),
c                        \frac{GL}{\mu}\sin(E), 0\right), \\
c     \dot{\vec q} & = & \frac{\mu}{L(1 - e\cos(E))}
c                  \left(-\sin(E), \frac{G}{L}\cos(E), 0\right)
c \end{eqnarray*}

      cos_e = dcos(e)
      sin_e = dsin(e)
      q_vec(1) = delau(6)**2*(cos_e - ecc)
      q_vec(2) = delau(7)*delau(6)*sin_e

c Cartisian coordinates

      x = mat(1,1)*q_vec(1) + mat(1,2)*q_vec(2)
      y = mat(2,1)*q_vec(1) + mat(2,2)*q_vec(2)
      z = mat(3,1)*q_vec(1) + mat(3,2)*q_vec(2)

      return
      end


      subroutine AppMag (r, delta, robs, h, g, alpha, mag, ierr)
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c This routine computes phase angle and apparent magnitude.
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c
c J-M. Petit  Observatoire de Besancon
c Version 1 : February 2004
c
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c INPUT
c     r     : Sun-object distance (R8)
c     delta : Earth-object distance (R8)
c     robs  : Sun-Earth distance (R8)
c     h     : Absolute magnitude of object (R8)
c     g     : Slope of object (R8)
c
c OUTPUT
c     alpha : Phase angle (R8)
c     mag   : Apparent magnitude (R8)
c     ierr  : Error code
c                0 : nominal run
c               10 : wrong input data
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
      implicit none

      integer(kind=4), intent(out) :: ierr
      real(kind=8), intent(in) :: r, delta, robs, h, g
      real(kind=8), intent(out) :: alpha, mag
      real(kind=8)
     $  Pi, raddeg, denom, phi1, phi2

      parameter
     $  (Pi = 3.141592653589793238d0, raddeg = 180.0d0/Pi)

      ierr = 0
      denom = 2.d0*r*delta
      if (denom == 0.d0) then
         ierr = 10
         return
      end if
      alpha = dacos(dmin1((-robs**2 + delta**2 + r**2)/denom,1.d0))
      phi1 = exp(-3.33d0*(dtan(alpha/2.0d0))**0.63d0)
      phi2 = exp(-1.87d0*(dtan(alpha/2.0d0))**1.22d0)
      mag = 5.d0*dlog10(r*delta) + h
     $  - 2.5d0*dlog10((1.d0 - g)*phi1 + g*phi2)

      return
      end


      subroutine BaryXV (jday, pos, vel, ierr)

c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c This routine gives the position and velocity in ecliptic heliocentric
c reference frame of the Solar System barycenter at a given time. Uses
c PlanetXV.
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c
c J-M. Petit  Observatoire de Besancon
c Version 1 : February 2004
c
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c INPUT
c     jday  : Time of elements (Julian day) (R8)
c
c OUTPUT
c     pos   : Position vector (3*R8)
c     vel   : Velocity vector (3*R8)
c     ierr  : Error code (I4)
c                0 : nominal run
c               20 : jday out of range
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
Cf2py intent(in) jday
Cf2py intent(out) pos
Cf2py intent(out) vel
Cf2py intent(out) ierr

      implicit none

      real(kind=8)
     $  jday, pos(3), vel(3), Pi, TwoPi, jday_min,
     $  jday_max, drad, mu

      integer(kind=4)
     $  ind, ierr, n_planets, istat

      parameter
     $  (Pi = 3.141592653589793238d0, TwoPi = 2.d0*Pi, drad = Pi/180.d0,
     $  jday_min = 2415020.0, jday_max = 2488070.0, n_planets = 8,
     $  mu = TwoPi**2)

      real(kind=8)
     $  pos_p(3), vel_p(3), masses(n_planets), msys, mp

      data masses /6023600.0d0,    ! Mercury
     $              408523.7d0,    ! Venus
     $              328900.56d0,   ! Earth + Moon
     $             3098708.0d0,    ! Mars
     $                1047.349d0,  ! Jupiter
     $                3497.898d0,  ! Saturn
     $               22902.98d0,   ! Uranus
     $               19412.24d0/   ! Neptune

      ierr = 0

c Jday out of range.
      if ((jday < jday_min) .or. (jday > jday_max)) then
         ierr = 20
         return
      end if

c Ok, do the math.
      pos(1) = 0.d0
      pos(2) = 0.d0
      pos(3) = 0.d0
      vel(1) = 0.d0
      vel(2) = 0.d0
      vel(3) = 0.d0
      msys = mu
      do ind = 1, n_planets
         call PlanetXV (ind, jday, pos_p, vel_p, istat)
         if (istat /= 0) then
            ierr = istat
            return
         end if
         mp = mu/masses(ind)
         msys = msys + mp
         pos(1) = pos(1) + mp*pos_p(1)
         pos(2) = pos(2) + mp*pos_p(2)
         pos(3) = pos(3) + mp*pos_p(3)
         vel(1) = vel(1) + mp*vel_p(1)
         vel(2) = vel(2) + mp*vel_p(2)
         vel(3) = vel(3) + mp*vel_p(3)
      end do
      pos(1) = pos(1)/msys
      pos(2) = pos(2)/msys
      pos(3) = pos(3)/msys
      vel(1) = vel(1)/msys
      vel(2) = vel(2)/msys
      vel(3) = vel(3)/msys

      return

      end

      subroutine PlanetXV (ind, jday, pos, vel, ierr)

c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c This routine gives the position and velocity in ecliptic heliocentric
c reference frame of a planet at a given time. Uses PlanetElem.
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c
c J-M. Petit  Observatoire de Besancon
c Version 1 : February 2004
c
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c INPUT
c     ind   : Planet index (I4)
c                1 : Mercury
c                2 : Venus
c                3 : Earth
c                4 : Mars
c                5 : Jupiter
c                6 : Saturn
c                7 : Uranus
c                8 : Neptune
c     jday  : Time of elements (Julian day) (R8)
c
c OUTPUT
c     pos   : Position vector (3*R8)
c     vel   : Velocity vector (3*R8)
c     ierr  : Error code (I4)
c                0 : nominal run
c               10 : Unknown planet index
c               20 : jday out of range
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
Cf2py intent(in) ind
Cf2py intent(in) jday
Cf2py intent(out) pos
Cf2py intent(out) vel
Cf2py intent(out) ierr

      implicit none

      real(kind=8)
     $  jday, pos(3), vel(3), Pi, TwoPi, jday_min,
     $  jday_max, drad, mu

      integer(kind=4)
     $  ind, ierr, n_planets, istat

      parameter
     $  (Pi = 3.141592653589793238d0, TwoPi = 2.d0*Pi, drad = Pi/180.d0,
     $  jday_min = 2415020.0, jday_max = 2488070.0, n_planets = 8,
     $  mu = TwoPi**2)

      real(kind=8)
     $  a, e, inc, node, peri, capm, masses(n_planets), gm

      data masses /6023600.0d0,    ! Mercury
     $              408523.7d0,    ! Venus
     $              328900.56d0,   ! Earth + Moon
     $             3098708.0d0,    ! Mars
     $                1047.349d0,  ! Jupiter
     $                3497.898d0,  ! Saturn
     $               22902.98d0,   ! Uranus
     $               19412.24d0/   ! Neptune

      ierr = 0

c Wrong planet index.
      if ((ind < 1) .or. (ind > n_planets)) then
         ierr = 10
         return
      end if

c Jday out of range.
      if ((jday < jday_min) .or. (jday > jday_max)) then
         ierr = 20
         return
      end if

c Ok, do the math.
      call PlanetElem (ind, jday, a, e, inc, node, peri, capm, istat)
      if (istat /= 0) then
         ierr = istat
         return
      end if
      gm = mu*(1.d0 + 1.d0/masses(ind))
      call coord_cart (gm, a, e, inc, node, peri, capm, pos(1), pos(2),
     $  pos(3), vel(1), vel(2), vel(3))

      return

      end

      subroutine PlanetElem (ind, jday, a, e, inc, node, peri, capm,
     $  ierr)

c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c This routine gives the osculating elements in heliocentric reference
c frame of a planet at a given time. From given elements and rates.
c Valid roughly from 1900 to 2100.
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c
c J-M. Petit  Observatoire de Besancon
c Version 1 : February 2004
c
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
c INPUT
c     ind   : Planet index (I4)
c                1 : Mercury
c                2 : Venus
c                3 : Earth
c                4 : Mars
c                5 : Jupiter
c                6 : Saturn
c                7 : Uranus
c                8 : Neptune
c     jday  : Time of elements (Julian day) (R8)
c
c OUTPUT
c     a     : Semi-major axis (R8)
c     e     : Eccentricity (R8)
c     inc   : Inclination (R8)
c     node  : Longitude of node (R8)
c     peri  : Argument of perihelion (R8)
c     capm  : Mean anomaly (R8)
c     ierr  : Error code (I4)
c                0 : nominal run
c               10 : Unknown planet index
c               20 : jday out of range
c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
Cf2py intent(in) ind
Cf2py intent(in) jday
Cf2py intent(out) a
Cf2py intent(out) e
Cf2py intent(out) inc
Cf2py intent(out) node
Cf2py intent(out) peri
Cf2py intent(out) capm
Cf2py intent(out) ierr

      implicit none

      real(kind=8)
     $  jday, a, e, inc, node, peri, capm, Pi, TwoPi, jday_min,
     $  jday_max, drad

      integer(kind=4)
     $  ind, ierr, n_planets

      parameter
     $  (Pi = 3.141592653589793238d0, TwoPi = 2.d0*Pi, drad = Pi/180.d0,
     $  jday_min = 2415020.0, jday_max = 2488070.0, n_planets = 8)

      real(kind=8)
     $  a_p(n_planets), e_p(n_planets), i_p(n_planets),
     $  node_p(n_planets), peri_p(n_planets), capm_p(n_planets),
     $  da_p(n_planets), de_p(n_planets), di_p(n_planets),
     $  dnode_p(n_planets), dperi_p(n_planets), dcapm_p(n_planets),
     $  jday_p, dt

c Elements are given in heliocentric reference frame.
      data
     $  jday_p /2451545.0/,
     $  a_p / 0.38709893, 0.72333199, 1.00000011, 1.52366231,
     $  5.20336301, 9.53707032, 19.19126393, 30.06896348/,
     $  e_p /0.20563069, 0.00677323, 0.01671022, 0.09341233,
     $  0.04839266, 0.05415060, 0.04716771, 0.00858587/,
     $  i_p /7.00487, 3.39471, 0.00005, 1.85061, 1.30530, 2.48446,
     $  0.76986, 1.76917/,
     $  node_p /48.33167, 76.68069, -11.26064, 49.57854, 100.55615,
     $  113.71504, 74.22988, 131.72169/,
     $  peri_p /77.45645, 131.53298, 102.94719, 336.04084, 14.75385,
     $  92.43194, 170.96424, 44.97135/,
     $  capm_p /252.25084000, 181.97973000, 100.46435000, 355.45332000,
     $  34.40438000, 49.94432000, 313.23218000, 304.88003000/,
     $  da_p/0.00000066, 0.00000092, -0.00000005, -0.00007221,
     $  0.00060737, -0.00301530, 0.00152025, -0.00125196/,
     $  de_p/0.00002527, -0.00004938, -0.00003804, 0.00011902,
     $  -0.00012880, -0.00036762, -0.00019150, 0.00002510/,
     $  di_p/-23.51, -2.86, -46.94, -25.47, -4.15, 6.11, -2.09, -3.64/,
     $  dnode_p /-446.30, -996.89, -18228.25, -1020.19, 1217.17,
     $  -1591.05, -1681.40, -151.25/,
     $  dperi_p /573.57, -108.80, 1198.28, 1560.78, 839.93, -1948.89,
     $  1312.56, -844.43/,
     $  dcapm_p /538101628.29, 210664136.06, 129597740.63, 68905103.78,
     $  10925078.35, 4401052.95, 1542547.79, 786449.21/

      ierr = 0

c Wrong planet index.
      if ((ind < 1) .or. (ind > n_planets)) then
         ierr = 10
         return
      end if

c Jday out of range.
      if ((jday < jday_min) .or. (jday > jday_max)) then
         ierr = 20
         return
      end if

c Ok, do the math.
c Rates are given in arcsecond per century, and angles in degree. Also we
C have all longitudes, when we need arguments. So tranformin arguments
C and radians.
      dt = (jday - jday_p)/365.25d0/100.d0
      a = a_p(ind) + dt*da_p(ind)
      e = e_p(ind) + dt*de_p(ind)
      inc = (i_p(ind) + dt*di_p(ind)/3600.d0)*drad
      node = (node_p(ind) + dt*dnode_p(ind)/3600.d0)*drad

c Longitude of pericenter
      peri = (peri_p(ind) + dt*dperi_p(ind)/3600.d0)*drad

c Mean longitude. Change to mean anomaly
      capm = (capm_p(ind) + dt*dcapm_p(ind)/3600.d0)*drad - peri

c Now get argument of pericenter
      peri = peri - node

      return

      end


c \subroutine{coord\_cart}

      subroutine coord_cart (mu, a, ecc, inc, capo, smallo, capm,
     $  x, y, z, vx, vy, vz)

c This routine transforms delaunay variables into cartisian
c variables.
c
c ANGLES ARE GIVEN IN RADIAN !!!!
c
c \subsection{Arguments}
c \subsubsection{Definitions}
c \begin{verse}
c \verb|a, e, inc, capo, smallo, capm| = osculating elements \\
c \verb|x, y, z, vx, vy, vz| = cartesian variables: $X, Y, Z, Px, Py, Pz$
c \end{verse}
c
c \subsubsection{Declarations}
c
Cf2py intent(in) mu
Cf2py intent(in) a
Cf2py intent(in) ecc
Cf2py intent(in) inc
Cf2py intent(in) capo
Cf2py intent(in) smallo
Cf2py intent(in) capm
Cf2py intent(out) x
Cf2py intent(out) y
Cf2py intent(out) z
Cf2py intent(out) vx
Cf2py intent(out) vy
Cf2py intent(out) vz

      implicit none

      real*8
     $  a, ecc, inc, capo, smallo, capm, mu, x, y, z, vx, vy, vz

c \subsection{Variables}
c \subsubsection{Definitions}
c \begin{verse}
c \verb|cos_e, sin_e, cos_i, sin_i| = sinus and cosines of $E$ and
c      $i$ \\
c \verb|delau| = Delaunay variables: $l, \cos(g), \sin(g), \cos(h),
c      \sin(h), L, G, H$ \\
c \verb|e| = eccentric anomaly \\
c \verb|mat| = rotation matrix \\
c \verb|q_vec, qp| = $q$ and $\dot q$ \\
c \verb|tmp| = temporary variable
c \end{verse}
c
c \subsubsection{Declarations}

      integer*4
     $  i

      real*8
     $  delau(8), cos_e, cos_i, e, mat(3,3), q_vec(2), qp(2),
     $  sin_e, sin_i, tmp, signe, Pi, TwoPi, f, de, fp, fpp, fppp

      parameter
     $  (Pi = 3.141592653589793238d0, TwoPi = 2.d0*Pi)

c Computation of sinus and cosines of angles.

      signe = 1.d0
      if (a .lt. 0.d0) signe = -1.d0
      cos_i = dcos(inc)
      sin_i = dsqrt(1.d0 - cos_i**2)
      delau(2) = dcos(smallo)
      delau(3) = dsin(smallo)
      delau(4) = dcos(capo)
      delau(5) = dsin(capo)
      delau(1) = capm - int(capm/TwoPi)*TwoPi
      delau(6) = signe*dsqrt(mu*a*signe)
      delau(7) = abs(delau(6))*dsqrt((1.d0 - ecc**2)*signe)

c Rotation matrix.
c The rotation matrix is the composition of 3 matrices: $R_{xq} =
c  R_3(-h) \cdot R_1(-i) \cdot R_3(-g)$:
c \begin{displaymath}
c     R_{xq} = \left(\matrix{
c       \cos(h)\cos(g)-\frac{H}{G}\sin(h)\sin(g)&
c       -\cos(h)\sin(g)-\frac{H}{G}\sin(h)\cos(g)&
c       \sqrt{1-\frac{H^2}{G^2}}\sin(h) \cr
c       \sin(h)\cos(g)+\frac{H}{G}\cos(h)\sin(g)&
c       -\sin(h)\sin(g)+\frac{H}{G}\cos(h)\cos(g)&
c       -\sqrt{1-\frac{H^2}{G^2}}\cos(h) \cr
c       \sqrt{1-\frac{H^2}{G^2}}\sin(g)&
c       \sqrt{1-\frac{H^2}{G^2}}\cos(g)&
c       \frac{H}{G} \cr}\right);
c \end{displaymath}

      mat(1,1) = delau(4)*delau(2) - cos_i*delau(5)*delau(3)
      mat(1,2) = -delau(4)*delau(3) - cos_i*delau(5)*delau(2)
      mat(2,1) = delau(5)*delau(2) + cos_i*delau(4)*delau(3)
      mat(2,2) = -delau(5)*delau(3) + cos_i*delau(4)*delau(2)
      mat(3,1) = sin_i*delau(3)
      mat(3,2) = sin_i*delau(2)

c Eccentric anomaly.
c We solve iteratively the equation:
c \begin{displaymath}
c     E - e \sin(E) = l
c \end{displaymath}
c using the accelerated Newton's method (see Danby).

      e = delau(1) + sign(.85d0, dsin(delau(1)))*ecc
      i = 0
 1000 continue
      sin_e = ecc*dsin(e)
      f = e - sin_e - delau(1)
      if (dabs(f) .gt. 1.d-14) then
         cos_e = ecc*dcos(e)
         fp = 1.d0 - cos_e
         fpp = sin_e
         fppp = cos_e
         de = -f/fp
         de = -f/(fp + de*fpp/2.d0)
         de = -f/(fp + de*fpp/2.d0 + de*de*fppp/6.d0)
         e = e + de
         i = i + 1
         if (i .lt. 20) goto 1000
         write (6, *) 'COORD_CART: No convergence: ', i, f
         write (6, *) mu, e, de
         write (6, *) a, ecc, inc
         write (6, *) capo, smallo, capm
         stop
      end if
      continue

c Coordinates relative to the orbit.
c The cartisian coordinate are given by $\vec X = R_{xq} \vec q$
c and $\vec P = R_{xq} \dot{\vec q}$, where:
c \begin{eqnarray*}
c     \vec q & = & \left(\frac{L^2}{\mu}(\cos(E) - e),
c                        \frac{GL}{\mu}\sin(E), 0\right), \\
c     \dot{\vec q} & = & \frac{\mu}{L(1 - e\cos(E))}
c                  \left(-\sin(E), \frac{G}{L}\cos(E), 0\right)
c \end{eqnarray*}

      cos_e = dcos(e)
      sin_e = dsin(e)
      q_vec(1) = delau(6)**2*(cos_e - ecc)/mu
      q_vec(2) = delau(7)*delau(6)*sin_e/mu
      tmp = mu/(delau(6)*(1.d0 - ecc*cos_e))
      qp(1) = -sin_e*tmp
      qp(2) = delau(7)*cos_e*tmp/delau(6)

c Cartisian coordinates

      x = mat(1,1)*q_vec(1) + mat(1,2)*q_vec(2)
      y = mat(2,1)*q_vec(1) + mat(2,2)*q_vec(2)
      z = mat(3,1)*q_vec(1) + mat(3,2)*q_vec(2)
      vx = mat(1,1)*qp(1) + mat(1,2)*qp(2)
      vy = mat(2,1)*qp(1) + mat(2,2)*qp(2)
      vz = mat(3,1)*qp(1) + mat(3,2)*qp(2)

      return
      end


      subroutine equat_ecl(ieqec,v_in,v_out,ierr)
!
!     Transformation of a vector v_in(3) from :
!        equator to ecliptic  : irot = +1
!        ecliptic to equator  : irot = -1
!        at J2000.
!     The equator is assumed to be the ICRF frame
!     The ecliptic is the so called 'conventional ecliptic'
!     going through the origin of the ICRF  with the obliquity
!     epsilon = 23°26'21".410 = 84381".41
!     It differs by ~ 50 mas from the inertial mean ecliptic(s) of J2000.
!
!     One can call equat_ecl(ieqec,vv,vv,ierr)
!
!     F. Mignard  OCA/CERGA
!     Version 1 : April 2003
!
!***************************************************************
! INPUT
!     Ieqec    : +1 ==> from equator to ecliptic ; -1 from ecliptic to equator.
!     v_in     :  input vector v_in(3) in the initial frame
!
! OUTPUT
!     v_out    :  output vector in the final frame v_out(3)
!     ierr     :  ierr = 0   :: normal exit
!                 ierr = 100 :: error ieqec neither 1 or -1 .
!
!***************************************************************
Cf2py intent(in) ieqec
Cf2py intent(in) v_in
Cf2py intent(out) v_out
Cf2py intent(out) ierr

      implicit none

      real*8
     $  epsilon, v_in(3), v_out(3), ww(3), coseps, sineps, Pi, secrad

c obliquity at J20000 in arcsec

      parameter
     $  (epsilon = 84381.41d0, Pi = 3.141592653589793238d0,
     $  secrad = Pi/180.d0/3600.d0)

      integer*4
     $  ieqec, ierr

      coseps = dcos(epsilon*secrad)
      sineps = dsin(epsilon*secrad)

c regular exit
      ierr   = 0

c to allow a call like ::  call equat_ecl(ieqec,vv,vv,ierr)
      ww(1)  = v_in(1)
      ww(2)  = v_in(2)
      ww(3)  = v_in(3)

      if (ieqec .eq. 1) then
        v_out(1) =   ww(1)
        v_out(2) =   coseps*ww(2) + sineps*ww(3)
        v_out(3) = - sineps*ww(2) + coseps*ww(3)
      else if (ieqec .eq. -1) then
        v_out(1) =   ww(1)
        v_out(2) =   coseps*ww(2) - sineps*ww(3)
        v_out(3) =   sineps*ww(2) + coseps*ww(3)
      else
c anomalous exit ieqec not allowed
        ierr     =   100
      end if

      return
      end


      subroutine newcomb (DJ,ROUT)
Cf2py intent(in) dj
Cf2py intent(out) rout

      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      double precision
     $  Z(8,121),Z0(80),Z1(80),Z2(80),Z3(80),Z4(80),Z5(80),Z6(80),
     $  Z7(80),Z8(80),Z9(80),ZA(80),ZB(80),ZC(8),ROU(3),CC(3,3),
     $  EL(21),C(5),RIN(3),X(3),Y(3),W(3),ROUT(3)
      integer i, k

      EQUIVALENCE(Z(1,  1),Z0(1))
      EQUIVALENCE(Z(1, 11),Z1(1))
      EQUIVALENCE(Z(1, 21),Z2(1))
      EQUIVALENCE(Z(1, 31),Z3(1))
      EQUIVALENCE(Z(1, 41),Z4(1))
      EQUIVALENCE(Z(1, 51),Z5(1))
      EQUIVALENCE(Z(1, 61),Z6(1))
      EQUIVALENCE(Z(1, 71),Z7(1))
      EQUIVALENCE(Z(1, 81),Z8(1))
      EQUIVALENCE(Z(1, 91),Z9(1))
      EQUIVALENCE(Z(1,101),ZA(1))
      EQUIVALENCE(Z(1,111),ZB(1))
      EQUIVALENCE(Z(1,121),ZC(1))
      DATA TWOPI/6.283185307179586D0/
      DATA STR/206264806.2470964D0/
      DATA RTD/57.29577951308232D0/
      DATA OBL0,C1,C2,C3/23.4522944D0,.1301250D-1,.163889D-5,.50278D-6/
      DATA TFIN/2433282.5D0/
      DATA Z0/   - 1.,  1., -   6.,-  11.,    26.,-  12.,     0.,    0.,
     1           - 1.,  2., -   3.,-   3., -   4.,    5.,     0.,    0.,
     2           - 1.,  3.,    15.,-   1., -   1.,-  18.,     0.,    0.,
     3           - 1.,  4.,    19.,-  13., -   2.,-   4.,     0.,    0.,
     4           - 1.,  0.,    33.,-  67., -  85.,-  39.,    24.,-  17.,
     5           - 1.,  1.,  2350.,-4223., -2059.,-1145., -   4.,    3.,
     6           - 1.,  2., -  65.,-  34.,    68.,-  14.,     6.,-  92.,
     7           - 1.,  3., -   3.,-   8.,    14.,-   8.,     1.,    7.,
     8           - 2.,  0., -   3.,    1.,     0.,    4.,     0.,    0.,
     9           - 2.,  1., -  99.,   60.,    84.,  136.,    23.,-   3./
      DATA Z1/   - 2.,  2., -4696., 2899.,  3588., 5815.,    10.,-   6.,
     1           - 2.,  3.,  1793.,-1735., - 595.,- 631.,    37.,-  56.,
     2           - 2.,  4.,    30.,-  33.,    40.,   33.,     5.,-  13.,
     3           - 3.,  2., -  13.,    1.,     0.,   21.,    13.,    5.,
     4           - 3.,  3., - 665.,   27.,    44., 1043.,     8.,    1.,
     5           - 3.,  4.,  1506.,- 396., - 381.,-1446.,   185.,- 100.,
     6           - 3.,  5.,   762.,- 683.,   126.,  148.,     6.,-   3.,
     7           - 3.,  6.,    12.,-  12.,    14.,   13., -   2.,    4.,
     8           - 4.,  3., -   3.,-   1.,     0.,    6.,     4.,    5.,
     9           - 4.,  4., - 188.,-  93., - 166.,  337.,     0.,    0./
      DATA Z2/   - 4.,  5., - 139.,-  38., -  51.,  189., -  31.,-   1.,
     1           - 4.,  6.,   146.,-  42., -  25.,-  91.,    12.,    0.,
     2           - 4.,  7.,     5.,-   4.,     3.,    5.,     0.,    0.,
     3           - 5.,  5., -  47.,-  69., - 134.,   93.,     0.,    0.,
     4           - 5.,  6., -  28.,-  25., -  39.,   43., -   8.,-   4.,
     5           - 5.,  7., - 119.,-  33., -  37.,  136., -  18.,-   6.,
     6           - 5.,  8.,   154.,-   1.,     0.,-  26.,     0.,    0.,
     7           - 6.,  5.,     0.,    0.,     0.,    0., -   2.,    6.,
     8           - 6.,  6., -   4.,-  38., -  80.,    8.,     0.,    0.,
     9           - 6.,  7., -   4.,-  13., -  24.,    7., -   2.,-   3./
      DATA Z3/   - 6.,  8., -   6.,-   7., -  10.,   10., -   2.,-   3.,
     1           - 6.,  9.,    14.,    3.,     3.,-  12.,     0.,    0.,
     2           - 7.,  7.,     8.,-  18., -  38.,-  17.,     0.,    0.,
     3           - 7.,  8.,     1.,-   6., -  12.,-   3.,     0.,    0.,
     4           - 7.,  9.,     1.,-   3., -   4.,    1.,     0.,    0.,
     5           - 7., 10.,     0.,    0., -   3.,    3.,     0.,    0.,
     6           - 8.,  8.,     9.,-   7., -  14.,-  19.,     0.,    0.,
     7           - 8.,  9.,     0.,    0., -   5.,-   4.,     0.,    0.,
     8           - 8., 12., -   8.,-  41., -  43.,    8., -   5.,-   9.,
     9           - 8., 13.,     0.,    0., -   9.,-   8.,     0.,    0./
      DATA Z4/   - 8., 14.,    21.,   24., -  25.,   22.,     0.,    0.,
     1           - 9.,  9.,     6.,-   1., -   2.,-  13.,     0.,    0.,
     2           - 9., 10.,     0.,    0., -   1.,-   4.,     0.,    0.,
     3           -10., 10.,     3.,    1.,     3.,-   7.,     0.,    0.,
     4             1.,- 2., -   5.,-   4., -   5.,    6.,     0.,    0.,
     5             1.,- 1., - 216.,- 167., -  92.,  119.,     0.,    0.,
     6             1.,  0., -   8.,-  47.,    27.,-   6.,     0.,    0.,
     7             2.,- 3.,    40.,-  10., -  13.,-  50.,     0.,    0.,
     8             2.,- 2.,  1960.,- 566., - 572.,-1973.,     0.,-   8.,
     9             2.,- 1., -1656.,- 616.,    64.,- 137.,     0.,    0./
      DATA Z5/     2.,  0., -  24.,   15., -  18.,-  25., -   8.,    2.,
     1             3.,- 4.,     1.,-   4., -   6.,    0.,     0.,    0.,
     2             3.,- 3.,    53.,- 118., - 154.,-  67.,     0.,    0.,
     3             3.,- 2.,   395.,- 153., -  77.,- 201.,     0.,    0.,
     4             3.,- 1.,     8.,    1.,     0.,    6.,     0.,    0.,
     5             4.,- 4.,    11.,   32.,    46.,-  17.,     0.,    0.,
     6             4.,- 3., - 131.,  482.,   460.,  125.,     7.,    1.,
     7             4.,- 2.,   525.,- 256.,    43.,   96.,     0.,    0.,
     8             4.,- 1.,     7.,-   5.,     6.,    8.,     0.,    0.,
     9             5.,- 5., -   7.,    1.,     0.,   12.,     0.,    0./
      DATA Z6/     5.,- 4.,    49.,   69.,    87.,-  62.,     0.,    0.,
     1             5.,- 3., -  38.,  200.,    87.,   17.,     0.,    0.,
     2             5.,- 2.,     3.,    1., -   1.,    3.,     0.,    0.,
     3             6.,- 6.,     0.,    0., -   4.,-   3.,     0.,    0.,
     4             6.,- 5., -  20.,-   2., -   3.,   30.,     0.,    0.,
     5             6.,- 4., - 104.,- 113., - 102.,   94.,     0.,    0.,
     6             6.,- 3., -  11.,  100., -  27.,-   4.,     0.,    0.,
     7             7.,- 6.,     3.,-   5., -   9.,-   5.,     0.,    0.,
     8             7.,- 5., -  49.,    3.,     4.,   60.,     0.,    0.,
     9             7.,- 4., -  78.,-  72., -  26.,   28.,     0.,    0./
      DATA Z7/     8.,- 7.,     1.,    3.,     5.,-   1.,     0.,    0.,
     1             8.,- 6.,     6.,-   8., -  12.,-   9.,     0.,    0.,
     2             8.,- 5.,    51.,-  10., -   8.,-  44.,     0.,    0.,
     3             8.,- 4., -  17.,-  12.,     5.,-   6.,     0.,    0.,
     4             9.,- 7.,     2.,    3.,     5.,-   3.,     0.,    0.,
     5             9.,- 6.,    13.,-  25., -  30.,-  16.,     0.,    0.,
     6             9.,- 5.,    60.,-  15., -   4.,-  17.,     0.,    0.,
     7            10.,- 7.,     2.,    5.,     7.,-   3.,     0.,    0.,
     8            10.,- 6., -   7.,   18.,    14.,    6.,     0.,    0.,
     9            10.,- 5.,     5.,-   2.,     0.,    0.,     0.,    0./
      DATA Z8/    11.,- 7.,     9.,   15.,    17.,-  10.,     0.,    0.,
     1            11.,- 6., -  12.,   42.,     8.,    3.,     0.,    0.,
     2            12.,- 7., -   4.,-   5., -   4.,    3.,     0.,    0.,
     3            13.,- 8., -  13.,-   1., -   1.,   15.,     0.,    0.,
     4            13.,- 7., -  30.,-  33., -   4.,    3.,     0.,    0.,
     5            15.,- 9.,    13.,-  16., -  17.,-  14.,     0.,    0.,
     6            15.,- 8.,   200.,-  30., -   1.,-   6.,     0.,    0.,
     7            17.,-10., -   2.,-   4., -   4.,    2.,     0.,    0.,
     8            17.,- 9., -  10.,   24.,     0.,    0.,     0.,    0.,
     9             1.,- 3., -   3.,-   1., -   2.,    5.,     0.,    0./
      DATA Z9/     1.,- 2., - 155.,-  52., -  78.,  193.,     7.,    0.,
     1             1.,- 1., -7208.,   59.,    56., 7067., -   1.,   17.,
     2             1.,  0., - 307.,-2582.,   227.,-  89.,    16.,    0.,
     3             1.,  1.,     8.,-  73.,    79.,    9.,     1.,   23.,
     4             2.,- 3.,    11.,   68.,   102.,-  17.,     0.,    0.,
     5             2.,- 2.,   136., 2728.,  4021.,- 203.,     0.,    0.,
     6             2.,- 1., - 537., 1518.,  1376.,  486.,    13.,  166.,
     7             2.,  0., -  22.,-  70., -   1.,-   8.,     0.,    0.,
     8             3.,- 4., -   5.,    2.,     3.,    8.,     0.,    0.,
     9             3.,- 3., - 162.,   27.,    43.,  278.,     0.,    0./
      DATA ZA/     3.,- 2.,    71.,  551.,   796.,- 104.,     6.,-   1.,
     1             3.,- 1., -  31.,  208.,   172.,   26.,     1.,   18.,
     2             4.,- 4., -   3.,-  16., -  29.,    5.,     0.,    0.,
     3             4.,- 3., -  43.,    9.,    13.,   73.,     0.,    0.,
     4             4.,- 2.,    17.,   78.,   110.,-  24.,     0.,    0.,
     5             4.,- 1., -   1.,   23.,    17.,    1.,     0.,    0.,
     6             5.,- 5.,     0.,    0., -   1.,-   3.,     0.,    0.,
     7             5.,- 4., -   1.,-   5., -  10.,    2.,     0.,    0.,
     8             5.,- 3., -   7.,    2.,     3.,   12.,     0.,    0.,
     9             5.,- 2.,     3.,    9.,    13.,-   4.,     0.,    0./
      DATA ZB/     1.,- 2., -   3.,   11.,    15.,    3.,     0.,    0.,
     1             1.,- 1., -  77.,  412.,   422.,   79.,     1.,    6.,
     2             1.,  0., -   3.,- 320.,     8.,-   1.,     0.,    0.,
     3             1.,  1.,     0.,-   8.,     8.,    0., -   1.,    6.,
     4             2.,- 3.,     0.,    0., -   3.,-   1.,     0.,    0.,
     5             2.,- 2.,    38.,- 101., - 152.,-  57.,     0.,    0.,
     6             2.,- 1.,    45.,- 103., - 103.,-  44.,    17., - 29.,
     7             2.,  0.,     2.,-  17.,     0.,    0.,     0.,    0.,
     8             3.,- 2.,     7.,-  20., -  30.,-  11.,     0.,    0.,
     9             3.,- 1.,     6.,-  16., -  16.,-   6.,     0.,    0./
      DATA ZC/     4.,- 2.,     1.,-   3., -   4.,-   1.,     0.,    0./

      CC(1,1) = +0.9999257180268403D0
      CC(1,2) = -0.0111782838886141D0
      CC(1,3) = -0.0048584357372842D0
      CC(2,1) = +0.0111782838782385D0
      CC(2,2) = +0.9999375206641666D0
      CC(2,3) = -0.0000271576311202D0
      CC(3,1) = +0.0048584357611567D0
      CC(3,2) = -0.0000271533600777D0
      CC(3,3) = +0.9999881973626738D0

      T  = (DJ - 2415020.D0)/36525.D0
      TP = (DJ - 2396758.D0)/365.25D0
      T18= (DJ - 2378496.D0)/36525.D0
      V = (DJ - 2451545.D0)/36525.D0
      V2 = V*V
      V3 = V*V2
      T50= (DJ - 2433282.423D0)/36525.D0
      EL( 2) =  0.16750401D-01 - T*(0.41879D-04 + 0.0503D-06*T)
      EL( 5) =  0.4908229466868880D+01 + (0.3000526416797348D-01
     1        +(0.7902463002085429D-05 +  0.5817764173314427D-07*T)*T)*T
     2        -(5.066D3 + 5.880D3*T + 0.476D3*T*T)/STR
      EL( 9) =  0.4881627934111871D+01 + (0.6283319509909086D+03
     1        + 0.5279620987282842D-05*T)*T
     2        +(0.33211D3 - 0.05299D3*T + 0.03959D3*T*T)/STR
      EL(10) =  0.6256583580497099D+01 + (0.6283019457267408D+03
     1        -(0.2617993877991491D-05 +  0.5817764173314427D-07*T)*T)*T
     2        +(5.358D3 + 5.747D3*T + 0.516D3*T*T)/STR
      EL(14) =  0.5859485105530519D+01 + (0.8399709200339593D+04
     1        +(0.4619304753611657D-04 +  0.6544984694978728D-07*T18)
     2        *T18)*T18
      EL(17) =  0.5807638839584459D+00 - (0.3375728238223387D+02
     1        -(0.3964806284113784D-04 +  0.3470781143063166D-07*T18)
     2        *T18)*T18
      EL(21) =  0.3933938487925745D+01 + (0.7101833330913285D+02
     1        -(0.1752456013106637D-03 -  0.1773109075921903D-06*T18)
     2        *T18)*T18
      EL(15) = EL(14) - EL(21)
      EL(16) = EL(14) - EL(17)
      D      = EL(14) - EL(9)
      ARG = D
      DL =    + 6466.D0*DSIN(ARG) + 13.D0*DSIN(3.*ARG)
      DR =    + 13384.D0*DCOS(ARG) +  30.D0*DCOS(3.*ARG)
      DBLARG = D + EL(15)
      ARG = DBLARG
      DL = DL +  177.D0*DSIN(ARG)
      DR = DR +  370.D0*DCOS(ARG)
      DBLARG = D - EL(15)
      ARG = DBLARG
      DL = DL -  425.D0*DSIN(ARG)
      DR = DR - 1332.D0*DCOS(ARG)
      DBLARG = 3.D0*D - EL(15)
      ARG = DBLARG
      DL = DL +   39.D0*DSIN(ARG)
      DR = DR +   80.D0*DCOS(ARG)
      DBLARG = D + EL(10)
      ARG = DBLARG
      DL = DL -   64.D0*DSIN(ARG)
      DR = DR -  140.D0*DCOS(ARG)
      DBLARG = D - EL(10)
      ARG = DBLARG
      DL = DL +  172.D0*DSIN(ARG)
      DR = DR + 360.D0*DCOS(ARG)
      ARG = D - EL(10) - EL(15)
      DL = DL - 13.D0*DSIN(ARG)
      DR = DR - 30.D0*DCOS(ARG)
      ARG = 2.D0*(EL(9)-EL(17))
      DL = DL - 13.D0*DSIN(ARG)
      DR = DR + 30.D0*DCOS(ARG)
      ARG = EL(16)
      DB =    + 577.D0*DSIN(ARG)
      DBLARG = EL(16) + EL(15)
      ARG = DBLARG
      DB = DB +  16.D0*DSIN(ARG)
      DBLARG = EL(16) - EL(15)
      ARG = DBLARG
      DB = DB -  47.D0*DSIN(ARG)
      DBLARG = EL(16) - 2.D0*(EL(9) - EL(17))
      ARG = DBLARG
      DB = DB +  21.D0*DSIN(ARG)
      ARG = ARG - EL(15)
      DB = DB + 5.D0*DSIN(ARG)
      ARG = EL(10) + EL(16)
      DB = DB + 5.D0*DSIN(ARG)
      ARG = EL(10) - EL(16)
      DB = DB + 5.D0*DSIN(ARG)
      GME = 0.43296383D+01 + .2608784648D+02*TP
      GV  = 0.19984020D+01 + .1021322923D+02*TP
      GMA = 0.19173489D+01 + .3340556174D+01*TP
      GJ  = 0.25836283D+01 + .5296346478D+00*TP
      GS  = 0.49692316D+01 + .2132432808D+00*TP
      GJ = GJ + 0.579904067D-02 * DSIN(5.D0*GS - 2.D0*GJ + 1.1719644977
     1     D0 - 0.397401726D-03 * TP)
      DG = 266.*DSIN(.555015D0 + 2.076942D0*T)
     1    +6400.*DSIN(4.035027D0 + .3525565D0*T)
     2    +(1882.D0-16.*T)*DSIN(.9990265D0 + 2.622706D0*T)
      EL(10) = DG/STR + EL(10)
      EL(12) =   DSIN(     EL(10)) * (6909794. - (17274. + 21.*T)*T)
     1         + DSIN(2.D0*EL(10)) * (  72334. -    362.*T)
     2         + DSIN(3.D0*EL(10)) * (   1050. -      8.*T)
     3         + DSIN(4.D0*EL(10)) *       17.
      RO     =                          30594. -    152.*T
     1         - DCOS(     EL(10)) * (7273841. - (18182. + 22.*T)*T)
     2         - DCOS(2.D0*EL(10)) * (  91374. -    457.*T)
     3         - DCOS(3.D0*EL(10)) * (   1446. -     11.*T)
     4         - DCOS(4.D0*EL(10)) *       25.
      EL(11) = 10.D0**(RO*1.D-09)
      DO 10 K=1,4
      DBLARG = Z(1,K)*GME + Z(2,K)*EL(10)
      ARG = DBLARG
      CS  = DCOS(ARG)
      SS  = DSIN(ARG)
      DL  =(Z(3,K)*CS  + Z(4,K)*SS )+ DL
      DR  =(Z(5,K)*CS  + Z(6,K)*SS )+ DR
   10 CONTINUE
      DO 20 K=5,44
      DBLARG = Z(1,K)*GV + Z(2,K)*EL(10)
      ARG = DBLARG
      CS  = DCOS(ARG)
      SS  = DSIN(ARG)
      DL  =(Z(3,K)*CS  + Z(4,K)*SS )+ DL
      DR  =(Z(5,K)*CS  + Z(6,K)*SS )+ DR
      DB  =(Z(7,K)*CS  + Z(8,K)*SS )+ DB
   20 CONTINUE
      DO 30 K=45,89
      DBLARG = Z(1,K)*GMA + Z(2,K)*EL(10)
      ARG = DBLARG
      CS  = DCOS(ARG)
      SS  = DSIN(ARG)
      DL  =(Z(3,K)*CS  + Z(4,K)*SS )+ DL
      DR  =(Z(5,K)*CS  + Z(6,K)*SS )+ DR
      DB  =(Z(7,K)*CS  + Z(8,K)*SS )+ DB
   30 CONTINUE
      DO 40 K=90,110
      DBLARG = Z(1,K)*GJ + Z(2,K)*EL(10)
      ARG = DBLARG
      CS  = DCOS(ARG)
      SS  = DSIN(ARG)
      DL  =(Z(3,K)*CS  + Z(4,K)*SS )+ DL
      DR  =(Z(5,K)*CS  + Z(6,K)*SS )+ DR
      DB  =(Z(7,K)*CS  + Z(8,K)*SS) +DB
   40 CONTINUE
      DO 50 K=111,121
      DBLARG = Z(1,K)*GS + Z(2,K)*EL(10)
      ARG = DBLARG
      CS  = DCOS(ARG)
      SS  = DSIN(ARG)
      DL  =(Z(3,K)*CS  + Z(4,K)*SS )+ DL
      DR  =(Z(5,K)*CS  + Z(6,K)*SS )+ DR
      DB  =(Z(7,K)*CS  + Z(8,K)*SS )+ DB
   50 CONTINUE
      C(1) = EL(11)*10.D0**(DR*1.D-09)
      C(4) = (DL + DG + EL(12))/STR + EL(9)
      C(5) = DB/STR
      C(2) = C(4)*RTD
      C(3) = C(5)*RTD
      BS = (-0.03903D3 + 0.03450D3*T - 0.00077D3*T*T)/STR
      BC = (+0.03363D3 + 0.01058D3*T + 0.00286D3*T*T)/STR
      BR = -0.01914D3/STR
      C(5) = C(5) + BS*DSIN(C(4)) + BC*DCOS(C(4)) +BR*DSIN(C(4)-EL(17))
      RS = (+0.01015D3 + 0.00035D3*T + 0.00023D3*T*T)/STR
      RC = (-0.02652D3 - 0.00002D3*T + 0.00054D3*T*T)/STR
      C(1) = C(1) + RS*DSIN(EL(10)) - RC*DCOS(EL(10))
      T2 = T*T
      T3 = T2*T
      OBL = OBL0 - C1*T - C2*T2 + C3*T3
      OBL = OBL/RTD
      RIN(1) = C(1)*DCOS(C(4))*DCOS(C(5))
      RIN(2) = C(1)*(DCOS(C(5))*DSIN(C(4))*DCOS(OBL)-DSIN(C(5))
     1*DSIN(OBL))
      RIN(3) = C(1)*(DCOS(C(5))*DSIN(C(4))*DSIN(OBL)+DSIN(C(5))
     1*DCOS(OBL))
      RDPSC=4.848136811D-06
      DPTTY=365242.2D0
      SDL=DJ
      IF (DJ-TFIN .lt. 0.) goto 101
      IF (DJ-TFIN .eq. 0.) goto 101
      IF (DJ-TFIN .gt. 0.) goto 100
  100 CONTINUE
      SDL=TFIN
  101 CONTINUE
      DT=(SDL-2415020.5D0)/DPTTY
      DT2=DT**2
      DY=DABS(DJ-TFIN)/DPTTY
      DY2=DY**2
      DY3=DY**3
      AK=((23042.53D0+139.73D0*DT+.06D0*DT2)*DY+(30.23D0-.27D0*DT)*DY2+1
     18.00D0*DY3)*RDPSC
      AW=((23042.53D0+139.73D0*DT+.06D0*DT2)*DY+(109.50D0+.39D0*DT)*DY2+
     118.32D0*DY3)*RDPSC
      BN=((20046.85D0-85.33D0*DT-.37D0*DT2)*DY+(-42.67D0-.37D0*DT)*DY2-4
     11.80D0*DY3)*RDPSC
      SINK=DSIN(AK)
      COSK=DCOS(AK)
      SINW=DSIN(AW)
      COSW=DCOS(AW)
      SINN=DSIN(BN)
      COSN=DCOS(BN)
      X(1) =-SINK*SINW   +COSK*COSW*COSN
      Y(1) =-COSK*SINW   -SINK*COSW*COSN
      W(1) =-COSW*SINN
      X(2) =SINK*COSW    +COSK*SINW*COSN
      Y(2) =COSK*COSW    -SINK*SINW*COSN
      W(2) =-SINW*SINN
      X(3) =COSK*SINN
      Y(3) =-SINK*SINN
      W(3) =COSN
      ROU(1) = 0.D0
      ROU(2) = 0.D0
      ROU(3) = 0.D0
      IF (DJ-TFIN .lt. 0.) goto 1
      IF (DJ-TFIN .eq. 0.) goto 1
      IF (DJ-TFIN .gt. 0.) goto 2
    1 CONTINUE
      DO  11  I=1,3
      ROU(I)=X(I)*RIN(1) + Y(I)*RIN(2)+W(I)*RIN(3)
   11 CONTINUE
      GO TO 3
    2 CONTINUE
      ROU(1)=      X(1)*RIN(1)   +X(2)*RIN(2)   +X(3)*RIN(3)
      ROU(2)=      Y(1)*RIN(1)   +Y(2)*RIN(2)   +Y(3)*RIN(3)
      ROU(3)=      W(1)*RIN(1)   +W(2)*RIN(2)   +W(3)*RIN(3)
    3 CONTINUE
      RIH = DSQRT(ROU(1)*ROU(1)+ROU(2)*ROU(2)+ROU(3)*ROU(3))
      RIG = DATAN2(ROU(2),ROU(1))
      DIG = DATAN2(ROU(3),DSQRT(ROU(1)*ROU(1)+ROU(2)*ROU(2)))
      RIG = RIG + 0.0D3/STR
      ROU(1) = RIH*DCOS(RIG)*DCOS(DIG)
      ROU(2) = RIH*DSIN(RIG)*DCOS(DIG)
      DO 4 I = 1,3
      ROUT(I) = CC(I,1)*ROU(1)+CC(I,2)*ROU(2)+CC(I,3)*ROU(3)
    4 CONTINUE
      RETURN
      END


      subroutine parse (command, nwmax, nw, word, lw)

c \subsection{Arguments}
c \subsubsection{Definitions}
c \begin{verse}
c \verb|command| = command line to parse \\
c \verb|lw()| = word lengthes \\
c \verb|nw| = number of words in command line \\
c \verb|nwmax| = maximum allowed number of words \\
c \verb|word()| = words in command line
c \end{verse}

c \subsubsection{Declarations}

      integer*4
     $     lw(1), nw, nwmax

      character
     $     command*(*), word(1)*(*)

c \subsection{Variables}
c \subsubsection{Internal variables}
c \begin{verse}
c \verb|k| = dummy index \\
c \verb|lc| = length of command line \\
c \end{verse}

c \subsubsection{Intrinsic Fortran functions used}
c \begin{verse}
c \verb|index|
c \end{verse}

c \subsubsection{Declarations}

      integer*4
     $     k, lc, lw0

c \subsection{Parsing}

      do nw = 1, nwmax
         lw(nw) = 0
      end do
      lc = len(command)
 1000 continue
      if ((command(lc:lc) .eq. char(0))
     $  .or. (command(lc:lc) .eq. ' ')) then
         lc = lc - 1
         if (lc .eq. 0) goto 1001
         goto 1000
      end if
 1001 continue
      nw = 0
      do k = 1, nwmax
          word(k) = ' '
      end do

 1100 continue
      if (lc .gt. 0) then

c Gets rid of leading space characters
         if (nw .ge. nwmax) then
            write (6, *) command
            write (6, *) 'parse: too many words in command line.'
            stop
         end if
 1050    continue
         if (command(1:1) .eq. ' ') then
            command = command (2:lc)
            lc = lc - 1
            goto 1050
         end if

c Finds a word

         nw = nw + 1
         lw0 = index(command, ' ') - 1
         if (lw0 .le. 0) then
            lw(nw) = lc
            word(nw) = command(1:lc)
            lc = -1
         else
            word (nw) = command (1:lw0)
            lw(nw) = lw0
            command = command (lw0+2:lc)
            lc = lc - lw0 - 1
         end if
         goto 1100
      end if

      return
      end

