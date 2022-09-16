c-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

      include 'utils.f'

      program XX

      implicit none

      integer(kind=4) obs_code, ierr, niter, nobjects, object_number
      integer(kind=4) output_lun, max_objects, max_iters
      integer(kind=4) field_number, i, j, version, k

      real(kind=8) Pi, TwoPi, drad, mu, theta, phi
      real(kind=8) gb, alpha, mag_limit, H_limit, MA

C     if in_sample=1 then we include this object, otherwise skip
      integer(kind=4) in_sample(2)

      parameter (Pi = 3.141592653589793238d0, TwoPi = 2.0d0*Pi,
     $     drad = Pi/180.0d0, mu = TwoPi**2)
      parameter (gb = 0.15, mag_limit=28, H_limit=14, version=3)
      
      real(kind=8) obs_jday, fake_jday
      real(kind=8) a, e, inc, node, peri, M, H, pos(6), obs_pos(3)
      real(kind=8) vel(3)
      real(kind=8) epoch_M
      real(kind=8) ros, fake_obs_pos(3), fake_ros, dec_cen
      real(kind=8) ra, dec, delta, radius, mag, ddec, dra, ra_cen
      real(kind=8) fake_ra, fake_dec, fake_delta, fake_mag, fake_M
      real(kind=8) fake_ra2, fake_dec2, fake_delta2, fake_mag2, fake_M2
      real(kind=8) fake_obs_pos2(3), fake_ros2
      real(kind=8) obs_ra, obs_dec, obs_radius, cos_obs_dec
      real(kind=8) r
      character in_str*120
      character output_filename*120, field*120
      character*80 message

      max_iters = 1E8
      obs_code = 500

C     New Horizons Summer 2020 Search Field Centre for 24-Jun-2020
C     the planned position and this date are used as the seed for 
C     planting sources
C     NHF1_20200624T00:00:00 RA=190741.37 DEC=-201619.37
C     NHF2_20200624T00:00:00 RA=191315.00 DEC=-203737.18
C     2020-06-24T00:00:00
C     To avoid bright star we moved to these centers
C     TGT_NHF120200824=OBJECT="NHF1_20200824"
C                             RA=190420.57 DEC=-201037.58 EQUINOX=2000.00
C     TGT_NHF220200824=OBJECT="NHF2_20200824"
C                             RA=191028.77 DEC=-201101.53 EQUINOX=2000.00
C     Coded centre is left fixed as that's what is used in original orbit
C     selection. F1 moved by 0.79 degrees, F2 moved by 0.78 degrees.  
C     Subaru FOV is radius of 0.75 degrees and we select sources within 1.2 
C     Thus, the edge of the field is not well populated.
C     0.79+0.75 ~ 1.60 leaving 0.4 degree
C     empty of sources.



      CALL parse_args(field, ra_cen, dec_cen, obs_jday, 
     $                fake_jday, max_objects)

C     set the date to start of 2022-09-01.. this is the base date for generating positions.
C     obs_jday = 2459823.5
      epoch_M = obs_jday
      call srand(int(epoch_M))

      cos_obs_dec = cos(dec_cen*drad)
      obs_radius = 1.2*drad

      do i = 1, len(in_str)
         in_str(i:i) = ' '
         output_filename(i:i) = ' '
      end do

      write(in_str, 7002) "PlantList",field,
     $        ra_cen,dec_cen,fake_jday,".txt"
 7002 format (2(a10,"_"),3(f15.4,"_"),a4)

      j = 1
      do i = 1, len(in_str) 
         if (in_str(i:i) .ne. ' ') then
            output_filename(j:j) = in_str(i:i)
            j = j+1
         endif
      end do
      output_filename = trim(output_filename)
      write(6,*) "Writing to "//output_filename

      output_lun = 11
      open (unit=output_lun, file=output_filename, status='new')

C     Get observatory location for primary/master location
      call ObsPos (obs_code, obs_jday, obs_pos, 
     $     vel, ros, ierr)

C     Get the observer location at this fake date.
      call ObsPos (obs_code, fake_jday, fake_obs_pos,
     $     vel, fake_ros, ierr)

C     Get the observer location at fake date + 1 day (for rates)
      call ObsPos (obs_code, fake_jday+1, fake_obs_pos2,
     $     vel, fake_ros2, ierr)

      write(output_lun, 9002) 'obj_id', 'RA', 'DEC', 'Delta', 
     $     'mag', 'a', 
     $     'e', 'inc',
     $     'node', 'peri', 'M', 'H', 'dra_arc', 'ddec_arc', 'r_sun'

      do i = 1, 2
C     Loop over making fake objects until we have max_objects in frame
         niter = 1
         nobjects = 1
         do while ((nobjects .le. max_objects) .and. 
     $        (niter .lt. max_iters))
            niter = niter + 1
            a = 30 + rand()*70
            e = rand()*0.5
            inc = Pi*rand()/2.0
            node = TwoPi*rand()
            peri = TwoPi*rand()
            M = TwoPi*rand()
            
            
            call pos_cart(a, e, inc, node, peri, M, pos(1),
     $           pos(2), pos(3))
            call RADECeclXV (pos, obs_pos, delta, ra, dec, ierr)
C     Given this random orbit determine if its on the image.

C     This loop select sources that are within RADIUS for a field 
C     but not in radius for any of the previous fields.
            in_sample(i) = 0
            do k = 1, i
               obs_ra = ra_cen*drad
               obs_dec = dec_cen*drad
               radius = sqrt(((ra-obs_ra)*cos_obs_dec)**2 + 
     $              (dec-obs_dec)**2)
               if ( radius .lt. obs_radius ) then 
                  if ( k .eq. i ) then
                     in_sample(i) = in_sample(i) + 1
                  else
                     in_sample(i) = in_sample(i) + 4
                  end if
               end if
            end do

            if ( in_sample(i) .eq. 1 ) then
C     Compute the Ground Based magnitude
               r = sqrt(pos(1)**2 + pos(2)**2 + pos(3)**2)
               mag = mag_limit+1
               
C     Distribute H randomly between 5 and 11
C     Until we get one bright enough
               do while ( mag .gt. mag_limit )
                  H = 5+rand()*9
                  call AppMag(r, delta, ros, H, gb, alpha, 
     $                 mag, ierr) 
               end do

C     This orbit / object is inside our sample. 
C     Compute circumstances at current observation.

               fake_M = MA(M, epoch_M, a, fake_jday)
               call pos_cart(a, e, inc, node, peri, fake_M, pos(1),
     $              pos(2), pos(3))
               call RADECeclXV (pos, fake_obs_pos, fake_delta, 
     $              fake_ra, fake_dec, ierr)
               r = sqrt(pos(1)**2 + pos(2)**2 + pos(3)**2)
               call AppMag(r, delta, fake_ros, H, gb, alpha, 
     $              mag, ierr) 

C     Compute position 1 day later to get sky motion rate
               fake_M = MA(M, epoch_M, a, fake_jday+1)
               
               call pos_cart(a, e, inc, node, peri, fake_M, pos(1),
     $              pos(2), pos(3))

               call RADECeclXV (pos, fake_obs_pos2, fake_delta2, 
     $              fake_ra2, fake_dec2, ierr)
               
               dra = (fake_ra2-fake_ra)*cos(fake_dec2)/24.0
               ddec = (fake_dec2-fake_dec)/24.0
               if ( i .gt. 1 ) then
                  object_number = -1 * nobjects
               else
                  object_number = nobjects
               end if
               write (output_lun, 9001) object_number,
     $              fake_ra/drad, fake_dec/drad, fake_delta, mag,
     $              a, e, inc/drad, node/drad, peri/drad,
     $              fake_M/drad, H, 3600*dra/drad, 3600.0*ddec/drad,
     $              r
            end if
C     Regardless of which sample this was in, increment the counter
            if ( in_sample(i) .gt. 0 ) then 
               nobjects = nobjects +1
            end if   
         end do
      end do

      STOP

 9001 format (i8,14(f16.6,1x))
 9002 format (a8,14(a16,1x))

      end program xx


      real*8 function MA(M, epoch_M, a, jday)
C     Move the Mean Annomally from jday to epoch_M

      real*8 M
      real*8 jday
      real*8 nu, TwoPi, epoch_M, a
      parameter (TwoPi=3.141592653589793238d0*2d0, nu=TwoPi/365.25d0)

      MA = M + (jday-epoch_M)*((nu/a**1.5))
      MA = MA - int(MA/TwoPi)*TwoPi
      return
      end function MA
      


      subroutine usage(message, ierr)
      character*80 message
      integer*4 ierr

      write(0,*) trim(message)
      write(0,*) ""

      write(0,*) "Usage: ClassyMakeFake FIELD RA DEC JD NITER"
      write(0,*) " FIELD -- Name of the field"
      write(0,*) " RA    -- RA of field center, in degrees"
      write(0,*) " DEC   -- RA of field center, in degrees"
      write(0,*) " JD    -- Julian Date assocaited to RA/DEC position"
      write(0,*) " JD    -- Julian Date for image to plant into"
      write(0,*) " NITER -- Number of KBOs to generate"
      write(0,*) ""

      call exit(ierr)
      end subroutine usage


      subroutine parse_args(name, ra, dec, obs_jd, fake_jd, max_objects)

C     Get the JD we will generate FAKE objects positions for.
C     Usage;  MakeFake obs_ra obs_dec obs_jday fake_jday number

      real*8 ra, dec, obs_jd, fake_jd
      character*80 message, command
      character*120 in_str, name
      integer*4 length
      integer*4 max_objects
      integer*4 nargs
      integer*4 argn


      nargs = COMMAND_ARGUMENT_COUNT()
      message = 'Wrong number of arguments'
      if (nargs .ne. 6) CALL usage(message, -1)

      argn = 0
      length = 80
      CALL GET_COMMAND_ARGUMENT(argn, command, length, ierr)
      if ( ierr .ne. 0 ) GOTO 1000

      argn = 1
      length = 120
      CALL GET_COMMAND_ARGUMENT(argn, name, length, ierr)
      if ( ierr .ne. 0 ) GOTO 1000

      argn = 2
      length = 80
      CALL GET_COMMAND_ARGUMENT(argn, in_str, length, ierr)
      if ( ierr .ne. 0 ) GOTO 1000
      read (in_str, *, err=1000) ra

      argn = 3
      CALL GET_COMMAND_ARGUMENT(argn, in_str, length, ierr)
      if (ierr .ne. 0) GOTO 1000
      read (in_str, *, err=1000) dec

      argn = 4
      CALL GET_COMMAND_ARGUMENT(argn, in_str, length, ierr)
      if (ierr .ne. 0) GOTO 1000
      read (in_str, *, err=1000) obs_jd

      argn = 5
      CALL GET_COMMAND_ARGUMENT(argn, in_str, length, ierr)
      if (ierr .ne. 0) GOTO 1000
      read (in_str, *, err=1000) fake_jd

C     Get the number of objects to generate
      argn = 6
      CALL GET_COMMAND_ARGUMENT(argn, in_str, length, ierr)
      if (ierr .ne. 0) GOTO 1000
      read (in_str, *, err=1000) max_objects

      write(0,*) "Executing command: ",command
      write(0,*) "Field Centre", ra, dec
      write(0,*) "Taken on JD:", obs_jd
      write(0,*) "Propogating elements to:", fake_jd
      write(0,*) "Number of objects:", max_objects
      RETURN

 1000 CONTINUE

      write(message, 1001) "Error parsing argument", argn
      message = trim(message)
      CALL usage(message, -1)
 1001 FORMAT('A20,I10')
      end subroutine parse_args
