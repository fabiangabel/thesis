!#########################################################
program main
!#########################################################

    use iso_c_binding
    implicit none
    real :: T1,T2

    interface cpp_interface

        subroutine commonFace(XYZL, XYZR, XYZCommon, AR) bind (C, name = "commonFace")

        use iso_c_binding
        implicit none

        real(kind = c_double),intent(inout),dimension(*) :: XYZL,XYZR,XYZCommon
        real(kind = c_double),intent(inout) :: AR

        end subroutine commonFace
    end interface cpp_interface

    call readData
    call cpu_time(T1)
    call findNeighbours
    call cpu_time(T2)
    print *, 'T2-T1 = ', T2-T1
    call writeParameterModule

end program main

!##########################################################
subroutine readData
!#########################################################

    use boundaryModule
    use charModule
    use geoModule
    use parameterModule
    use indexModule
    implicit none
    
    NB=NBLOCKS
    BLOCKUNIT=OFFSET+1
    write(BLOCK_CH,'(I1)') (BLOCKUNIT-OFFSET)
    BLOCKFILE='grid_'//trim(BLOCK_CH)//'.pre'
    
    open(UNIT=BLOCKUNIT,FILE=BLOCKFILE)
    rewind BLOCKUNIT
    read(BLOCKUNIT,*) NI,NJ,NK,NIJK,NINL,NOUT,NWAL,NBLO
    
    IBL(1)=0
    JBL(1)=0
    KBL(1)=0
    IJKBL(1)=0
    IJKINLBL(1)=0
    IJKOUTBL(1)=0
    IJKWALBL(1)=0
    IJKBLOBL(1)=0
    NIBL(1)=NI
    NJBL(1)=NJ
    NKBL(1)=NK
    NIJKBL(1)=NIJK
    NBLOBL(1)=NBLO
    NWALBL(1)=NWAL
    
    do B=2,NB
        BLOCKUNIT=OFFSET+B
        write(BLOCK_CH,'(I1)') (BLOCKUNIT-OFFSET)
        BLOCKFILE='grid_'//trim(BLOCK_CH)//'.pre'
        open(UNIT=BLOCKUNIT,FILE=BLOCKFILE)
        rewind BLOCKUNIT
        read(BLOCKUNIT,*) NI,NJ,NK,NIJK,NINL,NOUT,NWAL,NBLO

        BB=B-1
        IBL(B)=IBL(BB)+NIBL(BB)
        JBL(B)=JBL(BB)+NJBL(BB)
        KBL(B)=KBL(BB)+NKBL(BB)
        IJKBL(B)=IJKBL(BB)+NIJKBL(BB)
        IJKINLBL(B)=IJKINLBL(BB)+NINLBL(BB)
        IJKOUTBL(B)=IJKOUTBL(BB)+NOUTBL(BB)
        IJKWALBL(B)=IJKWALBL(BB)+NWALBL(BB)
        IJKBLOBL(B)=IJKBLOBL(BB)+NBLOBL(BB)
        NIBL(B)=NI
        NJBL(B)=NJ
        NKBL(B)=NK
        NIJKBL(B)=NIJK
        NINLBL(B)=NINL
        NOUTBL(B)=NOUT
        NWALBL(B)=NWAL
        NBLOBL(B)=NBLO
    end do

    call createMapping

    do B=1,NB
        call setBlockInd(B)
        BLOCKUNIT=OFFSET+B
        read(BLOCKUNIT,*)   (NEIGH(B,I),I=1,6)
        !print *, (NEIGH(B,I),I=1,6)
        !read(BLOCKUNIT,*)   (LK(KST+K),K=1,NK)
        !read(BLOCKUNIT,*)   (LI(IST+I),I=1,NI)
        
        read(BLOCKUNIT,*)   (X(IJKST+IJK),IJK=1,NIJK)
        read(BLOCKUNIT,*)   (Y(IJKST+IJK),IJK=1,NIJK)
        read(BLOCKUNIT,*)   (Z(IJKST+IJK),IJK=1,NIJK)
        read(BLOCKUNIT,*)   (XC(IJKST+IJK),IJK=1,NIJK)
        read(BLOCKUNIT,*)   (YC(IJKST+IJK),IJK=1,NIJK)
        read(BLOCKUNIT,*)   (ZC(IJKST+IJK),IJK=1,NIJK)
        
        read(BLOCKUNIT,*)   (IJKBINL(IJKINLST+IJK),IJK=1,NINL)
        read(BLOCKUNIT,*)   (IJKPINL(IJKINLST+IJK),IJK=1,NINL)
        read(BLOCKUNIT,*)   (IJKINL1(IJKINLST+IJK),IJK=1,NINL)
        read(BLOCKUNIT,*)   (IJKINL2(IJKINLST+IJK),IJK=1,NINL)
        read(BLOCKUNIT,*)   (IJKINL3(IJKINLST+IJK),IJK=1,NINL)
        read(BLOCKUNIT,*)   (IJKINL4(IJKINLST+IJK),IJK=1,NINL)
        
        read(BLOCKUNIT,*)   (IJKBOUT(IJKOUTST+IJK),IJK=1,NOUT)
        read(BLOCKUNIT,*)   (IJKPOUT(IJKOUTST+IJK),IJK=1,NOUT)
        read(BLOCKUNIT,*)   (IJKOUT1(IJKOUTST+IJK),IJK=1,NOUT)
        read(BLOCKUNIT,*)   (IJKOUT2(IJKOUTST+IJK),IJK=1,NOUT)
        read(BLOCKUNIT,*)   (IJKOUT3(IJKOUTST+IJK),IJK=1,NOUT)
        read(BLOCKUNIT,*)   (IJKOUT4(IJKOUTST+IJK),IJK=1,NOUT)
        
        read(BLOCKUNIT,*)   (IJKBWAL(IJKWALST+IJK),IJK=1,NWAL)
        read(BLOCKUNIT,*)   (IJKPWAL(IJKWALST+IJK),IJK=1,NWAL)
        read(BLOCKUNIT,*)   (IJKWAL1(IJKWALST+IJK),IJK=1,NWAL)
        read(BLOCKUNIT,*)   (IJKWAL2(IJKWALST+IJK),IJK=1,NWAL)
        read(BLOCKUNIT,*)   (IJKWAL3(IJKWALST+IJK),IJK=1,NWAL)
        read(BLOCKUNIT,*)   (IJKWAL4(IJKWALST+IJK),IJK=1,NWAL)

        read(BLOCKUNIT,*)   (IJKBBLO(IJKBLOST+IJK),IJK=1,NBLO)
        read(BLOCKUNIT,*)   (IJKPBLO(IJKBLOST+IJK),IJK=1,NBLO)
        read(BLOCKUNIT,*)   (IJKBLO1(IJKBLOST+IJK),IJK=1,NBLO)
        read(BLOCKUNIT,*)   (IJKBLO2(IJKBLOST+IJK),IJK=1,NBLO)
        read(BLOCKUNIT,*)   (IJKBLO3(IJKBLOST+IJK),IJK=1,NBLO)
        read(BLOCKUNIT,*)   (IJKBLO4(IJKBLOST+IJK),IJK=1,NBLO)
        
    end do

    print *, 'REMAPPING VALUES'
    do B=1,NB
        call setBlockInd(B)
        do IJKBLO=IJKBLOST+1,IJKBLOST+NBLO
            IJKBBLO(IJKBLO)=IJKBBLO(IJKBLO)+IJKST
            IJKPBLO(IJKBLO)=IJKPBLO(IJKBLO)+IJKST
            IJKBLO1(IJKBLO)=IJKBLO1(IJKBLO)+IJKST
            IJKBLO2(IJKBLO)=IJKBLO2(IJKBLO)+IJKST
            IJKBLO3(IJKBLO)=IJKBLO3(IJKBLO)+IJKST
            IJKBLO4(IJKBLO)=IJKBLO4(IJKBLO)+IJKST
        end do
        !
        do IJKINL=IJKINLST+1,IJKINLST+NINL
            IJKBINL(IJKINL)=IJKBINL(IJKINL)+IJKST
            IJKPINL(IJKINL)=IJKPINL(IJKINL)+IJKST
            IJKINL1(IJKINL)=IJKINL1(IJKINL)+IJKST
            IJKINL2(IJKINL)=IJKINL2(IJKINL)+IJKST
            IJKINL3(IJKINL)=IJKINL3(IJKINL)+IJKST
            IJKINL4(IJKINL)=IJKINL4(IJKINL)+IJKST
        end do
        !
        do IJKOUT=IJKOUTST+1,IJKOUTST+NOUT
            IJKBOUT(IJKOUT)=IJKBOUT(IJKOUT)+IJKST
            IJKPOUT(IJKOUT)=IJKPOUT(IJKOUT)+IJKST
            IJKOUT1(IJKOUT)=IJKOUT1(IJKOUT)+IJKST
            IJKOUT2(IJKOUT)=IJKOUT2(IJKOUT)+IJKST
            IJKOUT3(IJKOUT)=IJKOUT3(IJKOUT)+IJKST
            IJKOUT4(IJKOUT)=IJKOUT4(IJKOUT)+IJKST
        end do
        !
        do IJKWAL=IJKWALST+1,IJKWALST+NWAL
            IJKBWAL(IJKWAL)=IJKBWAL(IJKWAL)+IJKST
            IJKPWAL(IJKWAL)=IJKPWAL(IJKWAL)+IJKST
            IJKWAL1(IJKWAL)=IJKWAL1(IJKWAL)+IJKST
            IJKWAL2(IJKWAL)=IJKWAL2(IJKWAL)+IJKST
            IJKWAL3(IJKWAL)=IJKWAL3(IJKWAL)+IJKST
            IJKWAL4(IJKWAL)=IJKWAL4(IJKWAL)+IJKST
        end do

    end do

    !print *, 'REMAPPED VALUES'
    !do B=1,NB
        !call setBlockInd(B)
        !print *, 'BLOCK: ', B
        !do IJKWAL=IJKWALST+1,IJKWALST+NWAL
        !    IJKBWAL(IJKWAL)
        !print *, IJKPWAL(IJKWAL)
        !    IJKWAL1(IJKWAL)
        !    IJKWAL2(IJKWAL)
        !    IJKWAL3(IJKWAL)
        !    IJKWAL4(IJKWAL)
    !    end do
    !end do

end subroutine readData

!#########################################################
subroutine findNeighbours
!#########################################################

    use iso_c_binding
    use boundaryModule
    use geoModule
    use controlModule
    use indexModule
    implicit none
    integer :: iterationsCounter
    logical :: equalSize

    interface cpp_interface

        subroutine commonFace(XYZL,XYZR,XYZCommon,AR,XYZF) bind (C, name = "commonFace")

        use iso_c_binding
        implicit none

        real(kind = c_double),intent(inout),dimension(*) :: XYZL,XYZR,XYZCommon,XYZF
        real(kind = c_double),intent(inout) :: AR

        end subroutine commonFace
    end interface cpp_interface

    NF=0
    iterationsCounter=0

    ! use other block loop: B=1,NB
    do B=1,NB
        FACEBL(B)=NF
        call setBlockInd(B)
        IJKSTL=IJKBLOST+1
        IJKENL=IJKBLOST+NBLO
        print *, 'BLOCK: ',B
        neighbour: do INEIGH=1,6
            if (NEIGH(B,INEIGH).gt.0) then
                call setBlockInd(B,NEIGH(B,INEIGH))
                if (NBLOL.eq.NBLOR) then
                    equalSize=.true.
                else
                    equalSize=.false.
                end if
                IJKSTR=IJKBLOSTR+1
                IJKENR=IJKBLOSTR+NBLOR
                STARTED=.false.
                FOUND=.false.
                select case (INEIGH)
                    case (1)
                        !
                        !..........SOUTH..........
                        !
                        print *, 'SOUTH'
                        SouthOuter: do IJKL=IJKSTL,IJKENL
                            !
                            XYZL(1:3)=[X(IJKBLO2(IJKL)),Y(IJKBLO2(IJKL)),Z(IJKBLO2(IJKL))]
                            XYZL(4:6)=[X(IJKBLO1(IJKL)),Y(IJKBLO1(IJKL)),Z(IJKBLO1(IJKL))]
                            XYZL(7:9)=[X(IJKBLO3(IJKL)),Y(IJKBLO3(IJKL)),Z(IJKBLO3(IJKL))]
                            XYZL(10:12)=[X(IJKBLO4(IJKL)),Y(IJKBLO4(IJKL)),Z(IJKBLO4(IJKL))]
                            !
                            SouthInner: do IJKR=IJKSTR,IJKENR
                                iterationsCounter=iterationsCounter+1
                                !print *, iterationsCounter
                                !print *, IJKPBLO(IJKL),IJKPBLO(IJKR)
                                !
                                XYZR(1:3)=[X(IJKBLO1(IJKR)),Y(IJKBLO1(IJKR)),Z(IJKBLO1(IJKR))]
                                XYZR(4:6)=[X(IJKBLO2(IJKR)),Y(IJKBLO2(IJKR)),Z(IJKBLO2(IJKR))]
                                XYZR(7:9)=[X(IJKBLO4(IJKR)),Y(IJKBLO4(IJKR)),Z(IJKBLO4(IJKR))]
                                XYZR(10:12)=[X(IJKBLO3(IJKR)),Y(IJKBLO3(IJKR)),Z(IJKBLO3(IJKR))]
                                !
                                AR=0.0d0
                                call commonFace(XYZL,XYZR,XYZCommon,AR,XYZF)
                                !call reverseOrder(XYZCommon)
                                if (AR.gt.0.0d0) then
                                    STARTED=.true.
                                    FOUND=.true.
                                    NF=NF+1
                                    L(NF)=IJKPBLO(IJKL)
                                    R(NF)=IJKPBLO(IJKR)
                                    XF(NF)=XYZF(1)
                                    YF(NF)=XYZF(2)
                                    ZF(NF)=XYZF(3)
                                    call calcGrad(L(NF),R(NF),XF(NF),YF(NF),ZF(NF),FF(NF))
                                    call normalArea(&
                                        XYZCommon,L(NF),R(NF),ARF(NF),&
                                        DNF(NF),XPNF(NF),YPNF(NF),ZPNF(NF),&
                                        NXF(NF),NYF(NF),NZF(NF))
                                else if (.not.equalSize) then
                                    cycle SouthInner
                                else if (AR.le.0.0d0.and.STARTED) then
                                    IJKSTR=IJKR
                                    STARTED=.false.
                                    cycle SouthOuter
                                else if (FOUND) then
                                    IJKSTL=IJKL
                                    FOUND=.false.
                                    exit SouthOuter
                                else
                                    cycle SouthInner
                                end if
                            end do SouthInner
                        end do SouthOuter
                    case(2) 
                        !
                        !..........NORTH..........
                        !
                        print *, 'NORTH'
                        NorthOuter: do IJKL=IJKSTL,IJKENL
                            !
                            XYZL(1:3)=[X(IJKBLO1(IJKL)),Y(IJKBLO1(IJKL)),Z(IJKBLO1(IJKL))]
                            XYZL(4:6)=[X(IJKBLO2(IJKL)),Y(IJKBLO2(IJKL)),Z(IJKBLO2(IJKL))]
                            XYZL(7:9)=[X(IJKBLO4(IJKL)),Y(IJKBLO4(IJKL)),Z(IJKBLO4(IJKL))]
                            XYZL(10:12)=[X(IJKBLO3(IJKL)),Y(IJKBLO3(IJKL)),Z(IJKBLO3(IJKL))]
                            !
                            NorthInner: do IJKR=IJKSTR,IJKENR
                                iterationsCounter=iterationsCounter+1
                                !print *, iterationsCounter
                                !print *, IJKPBLO(IJKL),IJKPBLO(IJKR)
                                !
                                XYZR(1:3)=[X(IJKBLO2(IJKR)),Y(IJKBLO2(IJKR)),Z(IJKBLO2(IJKR))]
                                XYZR(4:6)=[X(IJKBLO1(IJKR)),Y(IJKBLO1(IJKR)),Z(IJKBLO1(IJKR))]
                                XYZR(7:9)=[X(IJKBLO3(IJKR)),Y(IJKBLO3(IJKR)),Z(IJKBLO3(IJKR))]
                                XYZR(10:12)=[X(IJKBLO4(IJKR)),Y(IJKBLO4(IJKR)),Z(IJKBLO4(IJKR))]
                                !
                                AR=0.0d0
                                call commonFace(XYZL,XYZR,XYZCommon,AR,XYZF)
                                call reverseOrder(XYZCommon)
                                if (AR.gt.0.0d0) then
                                    STARTED=.true.
                                    FOUND=.true.
                                    NF=NF+1
                                    L(NF)=IJKPBLO(IJKL)
                                    R(NF)=IJKPBLO(IJKR)
                                    XF(NF)=XYZF(1)
                                    YF(NF)=XYZF(2)
                                    ZF(NF)=XYZF(3)
                                    call calcGrad(L(NF),R(NF),XF(NF),YF(NF),ZF(NF),FF(NF))
                                    call normalArea(&
                                        XYZCommon,L(NF),R(NF),ARF(NF),&
                                        DNF(NF),XPNF(NF),YPNF(NF),ZPNF(NF),&
                                        NXF(NF),NYF(NF),NZF(NF))
                                else if (.not.equalSize) then
                                    cycle NorthInner
                                else if (AR.le.0.0d0.and.STARTED) then
                                    IJKSTR=IJKR
                                    STARTED=.false.
                                    IJKBLOSTR=IJKMARKR
                                    cycle NorthOuter
                                else if (FOUND) then
                                    IJKSTL=IJKL
                                    FOUND=.false.
                                    exit NorthOuter
                                else
                                    cycle NorthInner
                                end if
                            end do NorthInner
                        end do NorthOuter
                    case(3)
                        !
                        !..........WEST..........
                        !
                        print *, 'WEST'
                        WestOuter: do IJKL=IJKSTL,IJKENL
                            !
                            XYZL(1:3)=[X(IJKBLO1(IJKL)),Y(IJKBLO1(IJKL)),Z(IJKBLO1(IJKL))]
                            XYZL(4:6)=[X(IJKBLO2(IJKL)),Y(IJKBLO2(IJKL)),Z(IJKBLO2(IJKL))]
                            XYZL(7:9)=[X(IJKBLO4(IJKL)),Y(IJKBLO4(IJKL)),Z(IJKBLO4(IJKL))]
                            XYZL(10:12)=[X(IJKBLO3(IJKL)),Y(IJKBLO3(IJKL)),Z(IJKBLO3(IJKL))]
                            !
                            WestInner: do IJKR=IJKSTR,IJKENR
                                iterationsCounter=iterationsCounter+1
                                !print *, IJKPBLO(IJKL),IJKPBLO(IJKR)
                                !print *, iterationsCounter
                                !
                                XYZR(1:3)=[X(IJKBLO2(IJKR)),Y(IJKBLO2(IJKR)),Z(IJKBLO2(IJKR))]
                                XYZR(4:6)=[X(IJKBLO1(IJKR)),Y(IJKBLO1(IJKR)),Z(IJKBLO1(IJKR))]
                                XYZR(7:9)=[X(IJKBLO3(IJKR)),Y(IJKBLO3(IJKR)),Z(IJKBLO3(IJKR))]
                                XYZR(10:12)=[X(IJKBLO4(IJKR)),Y(IJKBLO4(IJKR)),Z(IJKBLO4(IJKR))]
                                !
                                AR=0.0d0
                                call commonFace(XYZL,XYZR,XYZCommon,AR,XYZF)
                                call reverseOrder(XYZCommon)
                                if (AR.gt.0.0d0) then
                                    STARTED=.true.
                                    FOUND=.true.
                                    NF=NF+1
                                    L(NF)=IJKPBLO(IJKL)
                                    R(NF)=IJKPBLO(IJKR)
                                    !print *, L(NF),R(NF)
                                    XF(NF)=XYZF(1)
                                    YF(NF)=XYZF(2)
                                    ZF(NF)=XYZF(3)
                                    call calcGrad(L(NF),R(NF),XF(NF),YF(NF),ZF(NF),FF(NF))
                                    call normalArea(&
                                        XYZCommon,L(NF),R(NF),ARF(NF),&
                                        DNF(NF),XPNF(NF),YPNF(NF),ZPNF(NF),&
                                        NXF(NF),NYF(NF),NZF(NF))
                                else if (.not.equalSize) then
                                    cycle WestInner
                                else if (AR.le.0.0d0.and.STARTED) then
                                    IJKSTR=IJKR
                                    STARTED=.false.
                                    cycle WestOuter
                                else if (FOUND) then
                                    IJKSTL=IJKL
                                    FOUND=.false.
                                    exit WestOuter
                                else
                                    cycle WestInner
                                end if
                            end do WestInner
                        end do WestOuter
                    case(4)
                        !
                        !..........EAST..........
                        !
                        print *, 'EAST'
                        EastOuter: do IJKL=IJKSTL,IJKENL
                            !
                            XYZL(1:3)=[X(IJKBLO2(IJKL)),Y(IJKBLO2(IJKL)),Z(IJKBLO2(IJKL))]
                            XYZL(4:6)=[X(IJKBLO1(IJKL)),Y(IJKBLO1(IJKL)),Z(IJKBLO1(IJKL))]
                            XYZL(7:9)=[X(IJKBLO3(IJKL)),Y(IJKBLO3(IJKL)),Z(IJKBLO3(IJKL))]
                            XYZL(10:12)=[X(IJKBLO4(IJKL)),Y(IJKBLO4(IJKL)),Z(IJKBLO4(IJKL))]
                            !
                            EastInner: do IJKR=IJKSTR,IJKENR
                                iterationsCounter=iterationsCounter+1
                                !print *, IJKPBLO(IJKL),IJKPBLO(IJKR)
                                !print *, iterationsCounter
                                !
                                XYZR(1:3)=[X(IJKBLO1(IJKR)),Y(IJKBLO1(IJKR)),Z(IJKBLO1(IJKR))]
                                XYZR(4:6)=[X(IJKBLO2(IJKR)),Y(IJKBLO2(IJKR)),Z(IJKBLO2(IJKR))]
                                XYZR(7:9)=[X(IJKBLO4(IJKR)),Y(IJKBLO4(IJKR)),Z(IJKBLO4(IJKR))]
                                XYZR(10:12)=[X(IJKBLO3(IJKR)),Y(IJKBLO3(IJKR)),Z(IJKBLO3(IJKR))]
                                !
                                AR=0.0d0
                                call commonFace(XYZL,XYZR,XYZCommon,AR,XYZF)
                                if (AR.gt.0.0d0) then
                                    STARTED=.true.
                                    FOUND=.true.
                                    NF=NF+1
                                    L(NF)=IJKPBLO(IJKL)
                                    R(NF)=IJKPBLO(IJKR)
                                    !print *, L(NF),R(NF)
                                    XF(NF)=XYZF(1)
                                    YF(NF)=XYZF(2)
                                    ZF(NF)=XYZF(3)
                                    call calcGrad(L(NF),R(NF),XF(NF),YF(NF),ZF(NF),FF(NF))
                                    call normalArea(&
                                        XYZCommon,L(NF),R(NF),ARF(NF),&
                                        DNF(NF),XPNF(NF),YPNF(NF),ZPNF(NF),&
                                        NXF(NF),NYF(NF),NZF(NF))
                                else if (.not.equalSize) then
                                    cycle EastInner
                                else if (AR.le.0.0d0.and.STARTED) then
                                    IJKSTR=IJKR
                                    STARTED=.false.
                                    cycle EastOuter
                                else if (FOUND) then
                                    FOUND=.false.
                                    IJKSTL=IJKL
                                    exit EastOuter
                                else
                                    cycle EastInner
                                end if
                            end do EastInner
                        end do EastOuter
                    case(5)
                        !
                        !..........BOTTOM..........
                        !
                        print *, 'BOTTOM'
                        BottomOuter: do IJKL=IJKSTL,IJKENL
                            !
                            XYZL(1:3)=[X(IJKBLO1(IJKL)),Y(IJKBLO1(IJKL)),Z(IJKBLO1(IJKL))]
                            XYZL(4:6)=[X(IJKBLO2(IJKL)),Y(IJKBLO2(IJKL)),Z(IJKBLO2(IJKL))]
                            XYZL(7:9)=[X(IJKBLO4(IJKL)),Y(IJKBLO4(IJKL)),Z(IJKBLO4(IJKL))]
                            XYZL(10:12)=[X(IJKBLO3(IJKL)),Y(IJKBLO3(IJKL)),Z(IJKBLO3(IJKL))]
                            !
                            BottomInner: do IJKR=IJKSTR,IJKENR
                                iterationsCounter=iterationsCounter+1
                                !print *, IJKPBLO(IJKL),IJKPBLO(IJKR)
                                !print *, iterationsCounter
                                !
                                XYZR(1:3)=[X(IJKBLO2(IJKR)),Y(IJKBLO2(IJKR)),Z(IJKBLO2(IJKR))]
                                XYZR(4:6)=[X(IJKBLO1(IJKR)),Y(IJKBLO1(IJKR)),Z(IJKBLO1(IJKR))]
                                XYZR(7:9)=[X(IJKBLO3(IJKR)),Y(IJKBLO3(IJKR)),Z(IJKBLO3(IJKR))]
                                XYZR(10:12)=[X(IJKBLO4(IJKR)),Y(IJKBLO4(IJKR)),Z(IJKBLO4(IJKR))]
                                !
                                AR=0.0d0
                                call commonFace(XYZL,XYZR,XYZCommon,AR,XYZF)
                                call reverseOrder(XYZCommon)
                                if (AR.gt.0.0d0) then
                                    STARTED=.true.
                                    FOUND=.true.
                                    NF=NF+1
                                    L(NF)=IJKPBLO(IJKL)
                                    R(NF)=IJKPBLO(IJKR)
                                    XF(NF)=XYZF(1)
                                    YF(NF)=XYZF(2)
                                    ZF(NF)=XYZF(3)
                                    call calcGrad(L(NF),R(NF),XF(NF),YF(NF),ZF(NF),FF(NF))
                                    call normalArea(&
                                        XYZCommon,L(NF),R(NF),ARF(NF),&
                                        DNF(NF),XPNF(NF),YPNF(NF),ZPNF(NF),&
                                        NXF(NF),NYF(NF),NZF(NF))
                                else if (.not.equalSize) then
                                    cycle BottomInner
                                else if (AR.le.0.0d0.and.STARTED) then
                                    IJKSTR=IJKR
                                    STARTED=.false.
                                    cycle BottomOuter
                                else if (FOUND) then
                                    FOUND=.false.
                                    IJKSTL=IJKL
                                    exit BottomOuter
                                else
                                    cycle BottomInner
                                end if
                            end do BottomInner
                        end do BottomOuter
                    case(6) 
                        !
                        !..........TOP..........
                        !
                        print *, 'TOP'
                        TopOuter: do IJKL=IJKSTL,IJKENL
                            !
                            XYZL(1:3)=[X(IJKBLO2(IJKL)),Y(IJKBLO2(IJKL)),Z(IJKBLO2(IJKL))]
                            XYZL(4:6)=[X(IJKBLO1(IJKL)),Y(IJKBLO1(IJKL)),Z(IJKBLO1(IJKL))]
                            XYZL(7:9)=[X(IJKBLO3(IJKL)),Y(IJKBLO3(IJKL)),Z(IJKBLO3(IJKL))]
                            XYZL(10:12)=[X(IJKBLO4(IJKL)),Y(IJKBLO4(IJKL)),Z(IJKBLO4(IJKL))]
                            !
                            TopInner: do IJKR=IJKSTR,IJKENR
                                iterationsCounter=iterationsCounter+1
                                !print *, IJKPBLO(IJKL),IJKPBLO(IJKR)
                                !print *, iterationsCounter
                                !
                                XYZR(1:3)=[X(IJKBLO1(IJKR)),Y(IJKBLO1(IJKR)),Z(IJKBLO1(IJKR))]
                                XYZR(4:6)=[X(IJKBLO2(IJKR)),Y(IJKBLO2(IJKR)),Z(IJKBLO2(IJKR))]
                                XYZR(7:9)=[X(IJKBLO4(IJKR)),Y(IJKBLO4(IJKR)),Z(IJKBLO4(IJKR))]
                                XYZR(10:12)=[X(IJKBLO3(IJKR)),Y(IJKBLO3(IJKR)),Z(IJKBLO3(IJKR))]
                                !
                                AR=0.0d0
                                call commonFace(XYZL,XYZR,XYZCommon,AR,XYZF)
                                if (AR.gt.0.0d0) then
                                    STARTED=.true.
                                    FOUND=.true.
                                    NF=NF+1
                                    L(NF)=IJKPBLO(IJKL)
                                    R(NF)=IJKPBLO(IJKR)
                                    XF(NF)=XYZF(1)
                                    YF(NF)=XYZF(2)
                                    ZF(NF)=XYZF(3)
                                    call calcGrad(L(NF),R(NF),XF(NF),YF(NF),ZF(NF),FF(NF))
                                    call normalArea(&
                                        XYZCommon,L(NF),R(NF),ARF(NF),&
                                        DNF(NF),XPNF(NF),YPNF(NF),ZPNF(NF),&
                                        NXF(NF),NYF(NF),NZF(NF))
                                else if (.not.equalSize) then
                                    cycle TopInner
                                else if (AR.le.0.0d0.and.STARTED) then
                                    IJKSTR=IJKR
                                    STARTED=.false.
                                    cycle TopOuter
                                else if (FOUND) then
                                    FOUND=.false.
                                    IJKSTL=IJKL
                                    exit TopOuter
                                else
                                    cycle TopInner
                                end if
                            end do TopInner
                        end do TopOuter
                end select
            end if
        end do neighbour
        NFACEBL(B)=NF-FACEBL(B)
        call writeBlockData(B)
    end do

    print *, 'No. iterations: ', iterationsCounter

end subroutine findNeighbours

!#####################################################
subroutine writeBlockData(IB)
!#####################################################

    use boundaryModule
    use geoModule
    use indexModule
    implicit none
    integer,intent(in) :: IB
    integer :: BLOCKUNIT,OFFSET
    character(len=20) :: UNIT_CH,BLOCKFILE
    OFFSET=20
    BLOCKUNIT=OFFSET+IB
    call setBlockInd(IB)
    
    !
    ! read in rest of relevant data
    read(BLOCKUNIT,*)  (FX(I), I=1,NIJK)
    read(BLOCKUNIT,*)  (FY(I), I=1,NIJK)
    read(BLOCKUNIT,*)  (FZ(I), I=1,NIJK)
    read(BLOCKUNIT,*)  DX,DY,DZ,VOL
    read(BLOCKUNIT,*)  (SRDINL(I),I=1,NINL)
    read(BLOCKUNIT,*)  (SRDOUT(I),I=1,NOUT)
    read(BLOCKUNIT,*)  (SRDWAL(I),I=1,NWAL)
    !
    ! overwrite data back to input file
    !
    write(UNIT_CH,'(I1)') IB
    BLOCKFILE='grid_'//trim(UNIT_CH)//'.out'
    
    open(UNIT=BLOCKUNIT,FILE=BLOCKFILE)
    print *, 'WRITING TO FILE: ', BLOCKFILE
    rewind BLOCKUNIT
    N=(NK-2)*(NI-2)*(NJ-2)
    write(BLOCKUNIT,*) NI,NJ,NK,NIJK,NINL,NOUT,NWAL,NBLO,NFACE,N,IJKST
    !write(BLOCKUNIT,*) (NEIGH(B,I),I=1,6)
    !write(BLOCKUNIT,*) (LK(KST+K),K=1,NK)
    !write(BLOCKUNIT,*) (LI(IST+I),I=1,NI)
    write(BLOCKUNIT,*) (X(IJKST+IJK),IJK=1,NIJK)
    write(BLOCKUNIT,*) (Y(IJKST+IJK),IJK=1,NIJK)
    write(BLOCKUNIT,*) (Z(IJKST+IJK),IJK=1,NIJK)
    write(BLOCKUNIT,*) (XC(IJKST+IJK),IJK=1,NIJK)
    write(BLOCKUNIT,*) (YC(IJKST+IJK),IJK=1,NIJK)
    write(BLOCKUNIT,*) (ZC(IJKST+IJK),IJK=1,NIJK)

    write(BLOCKUNIT,*) (IJKBBLO(IJKBLOST+IJK),IJK=1,NBLO)
    write(BLOCKUNIT,*) (IJKPBLO(IJKBLOST+IJK),IJK=1,NBLO)
    write(BLOCKUNIT,*) (IJKBLO1(IJKBLOST+IJK),IJK=1,NBLO)
    write(BLOCKUNIT,*) (IJKBLO2(IJKBLOST+IJK),IJK=1,NBLO)
    write(BLOCKUNIT,*) (IJKBLO3(IJKBLOST+IJK),IJK=1,NBLO)
    write(BLOCKUNIT,*) (IJKBLO4(IJKBLOST+IJK),IJK=1,NBLO)

    write(BLOCKUNIT,*) (IJKBINL(IJKINLST+IJK),IJK=1,NINL)
    write(BLOCKUNIT,*) (IJKPINL(IJKINLST+IJK),IJK=1,NINL)
    write(BLOCKUNIT,*) (IJKINL1(IJKINLST+IJK),IJK=1,NINL)
    write(BLOCKUNIT,*) (IJKINL2(IJKINLST+IJK),IJK=1,NINL)
    write(BLOCKUNIT,*) (IJKINL3(IJKINLST+IJK),IJK=1,NINL)
    write(BLOCKUNIT,*) (IJKINL4(IJKINLST+IJK),IJK=1,NINL)

    write(BLOCKUNIT,*) (IJKBOUT(IJKOUTST+IJK),IJK=1,NOUT)
    write(BLOCKUNIT,*) (IJKPOUT(IJKOUTST+IJK),IJK=1,NOUT)
    write(BLOCKUNIT,*) (IJKOUT1(IJKOUTST+IJK),IJK=1,NOUT)
    write(BLOCKUNIT,*) (IJKOUT2(IJKOUTST+IJK),IJK=1,NOUT)
    write(BLOCKUNIT,*) (IJKOUT3(IJKOUTST+IJK),IJK=1,NOUT)
    write(BLOCKUNIT,*) (IJKOUT4(IJKOUTST+IJK),IJK=1,NOUT)

    write(BLOCKUNIT,*) (IJKBWAL(IJKWALST+IJK),IJK=1,NWAL)
    write(BLOCKUNIT,*) (IJKPWAL(IJKWALST+IJK),IJK=1,NWAL)
    write(BLOCKUNIT,*) (IJKWAL1(IJKWALST+IJK),IJK=1,NWAL)
    write(BLOCKUNIT,*) (IJKWAL2(IJKWALST+IJK),IJK=1,NWAL)
    write(BLOCKUNIT,*) (IJKWAL3(IJKWALST+IJK),IJK=1,NWAL)
    write(BLOCKUNIT,*) (IJKWAL4(IJKWALST+IJK),IJK=1,NWAL)
    !
    ! untouched variables
    write(BLOCKUNIT,*) (FX(I), I=1,NIJK)
    write(BLOCKUNIT,*) (FY(I), I=1,NIJK)
    write(BLOCKUNIT,*) (FZ(I), I=1,NIJK)
    write(BLOCKUNIT,*) DX,DY,DZ,VOL
    write(BLOCKUNIT,*)  (SRDINL(I),I=1,NINL)
    write(BLOCKUNIT,*)  (SRDOUT(I),I=1,NOUT)
    write(BLOCKUNIT,*)  (SRDWAL(I),I=1,NWAL)
    !
    write(BLOCKUNIT,*) (L(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (R(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (XF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (YF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (ZF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (FF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (ARF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (DNF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (XPNF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (YPNF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (ZPNF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (NXF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (NYF(FACEST+I),I=1,NFACE)
    write(BLOCKUNIT,*) (NZF(FACEST+I),I=1,NFACE)
    !
    ! Map
    !
    print *, NXYZA
    write(BLOCKUNIT,*) (MIJK(IJK),IJK=1,NXYZA)
    close(unit=BLOCKUNIT)
    
end subroutine writeBlockData

!#####################################################
subroutine createMapping
!#####################################################
    
    use indexModule
    implicit none

    IJK_GLO=-1
    do B=1,NB
        NBL(B)=0
        call setBlockInd(B)
        do K=2,NK-1
        do I=2,NI-1
        do J=2,NJ-1
            NBL(B)=NBL(B)+1
            IJK_GLO=IJK_GLO+1
            IJK_LOC=IJKST+(K-1)*NI*NJ+(I-1)*NJ+J
            MIJK(IJK_LOC)=IJK_GLO
        end do
        end do
        end do
    end do

end subroutine createMapping

!#####################################################
subroutine writeParameterModule
!#####################################################

    use indexModule
    implicit none

    OPEN(UNIT=9,FILE='parameterModule.f90')
    REWIND 9
    read(9,*) ! 'module parameterModule'
    read(9,*) ! 'implicit none'
    read(9,*) ! 'integer, parameter :: ', 'NXA=', NIA
    read(9,*) ! 'integer, parameter :: ', 'NYA=', NJA
    read(9,*) ! 'integer, parameter :: ', 'NZA=', NKA
    read(9,*) ! 'integer, parameter :: ', 'NXYZA=', NIJKA
    read(9,*) ! 'integer, parameter :: ', 'NINLAL=', NINLA
    read(9,*) ! 'integer, parameter :: ', 'NOUTAL=', NOUTA
    read(9,*) ! 'integer, parameter :: ', 'NWALAL=', NWALA
    read(9,*) ! 'integer, parameter :: ', 'NBLOAL=', NBLOA
    read(9,*) !   'integer, parameter :: ', 'NBLOCKS=',NB
    read(9,*) ! 'integer, parameter :: ', 'PREC=',PREC
    write(9,'(4X, A22, A8, I6)') 'integer, parameter :: ', 'NFACEAL=',NF
    write(9,'(A)') 'end module parameterModule'

end subroutine writeParameterModule