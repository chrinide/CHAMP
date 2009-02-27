##########################################################################
# MACHINE-DEPENDENT COMPILATION OPTIONS FOR CHAMP
##########################################################################

system := $(shell uname)
hostname := $(shell uname -n)

####################### DEFAULTS ########################################

# Libraries --------------------------------------------------------------

LIBHOME=../lib

QUENCH=-L$(LIBHOME)/SimulatedAnnealing/quench_anneal/lib -lquench -lquench_seq
CYRUSLIB=-L$(LIBHOME)/lib -lcyrus

LINPACK=-L$(LIBHOME)/lib2/linpack -llinpack
#LINPACK=-L/usr/lib -llinpack

LAPACK=-L$(LIBHOME)/lib2/lapack -llapack
#LAPACK=-L/usr/lib/ -llapack

BLAS=-L$(LIBHOME)/lib2/blas -lblas
#BLAS=-L/usr/lib/ -lblas

PSPLINE=-L$(LIBHOME)/lib2/pspline/pspline -lpspline

EINSPLINE=-L$(LIBHOME)/lib2/einspline/lib -leinspline

CHAMP_LIBS=$(CYRUSLIB) $(LINPACK) $(LAPACK) $(BLAS) $(QUENCH) $(LINPACK) $(BLAS) $(PSPLINE) $(EINSPLINE)

# C compilation ------------------------------------------------------------

CHAMP_C=icc
CHAMP_CXX=icpc
CHAMP_MPIC=icc

CHAMP_C_FAST=-O3 -DUNDERSCORE
CHAMP_C_PROF=-O3 -DUNDERSCORE -pg
CHAMP_C_DEBUG=-DUNDERSCORE
CHAMP_C_FLAGS=$(CHAMP_C_FAST)
CHAMP_C_MPI_FLAGS=$(CHAMP_C_FLAGS)

# Fortran compilation ------------------------------------------------------

# These are defaults using the ifort compiler and are used e.g. on the old AMD cluster dft, and on nanolab
CHAMP_F95=ifort
CHAMP_MPIF95=mpif77

CHAMP_F95_FAST= -zero -r8 -pad -align all -O3 -fpp -ip 
CHAMP_F95_PROF= -zero -r8 -pad -align all -O3 -fpp -pg 
CHAMP_F95_DEBUG=-zero -r8 -pad -align all -O0 -fpp -ip -check all -check nooutput_conversion -debug extended -debug-parameters all -g -traceback -error_limit 1 -DDEBUG

# by default, compilation for f77 is the same than for f95
CHAMP_F77=$(CHAMP_F95)
CHAMP_MPIF77=$(CHAMP_MPIF95)
CHAMP_F77_FAST=$(CHAMP_F95_FAST) -extend_source
CHAMP_F77_DEBUG=$(CHAMP_F95_DEBUG) -extend_source
CHAMP_F77_PROF=$(CHAMP_F95_PROF) -extend_source

# by default, fast options
CHAMP_F95_FLAGS=$(CHAMP_F95_FAST)
CHAMP_F77_FLAGS=$(CHAMP_F77_FAST) 

# by default, same options for MPI
CHAMP_F95_MPI_FLAGS=$(CHAMP_F95_FLAGS) -DMPI
CHAMP_F77_MPI_FLAGS=$(CHAMP_F77_FLAGS) -DMPI

# Linking  ------------------------------------------------------------------

# by default, linker is f95 compiler
CHAMP_LD=$(CHAMP_F95)
CHAMP_LD_MPI=$(CHAMP_MPIF95)

CHAMP_LD_FAST=$(CHAMP_F95_FLAGS) -static
CHAMP_LD_PROF=-O3 -pg
CHAMP_LD_DEBUG=-static -align all
CHAMP_LD_IPO=-O3 -ipo -static -align all -fast

CHAMP_LD_FLAGS=$(CHAMP_LD_FAST)

CHAMP_LD_END=
#CHAMP_LD_END_MPI=-lmpi -lpthread
CHAMP_LD_END_MPI=

# Executables -------------------------------------------------------------

CHAMP_EXE=champ.exe
CHAMP_MPI_EXE=champ_mpi.exe
CHAMP_DEBUG_EXE=champ_debug.exe

# Export these for compiling the libraries
export CHAMP_F77 CHAMP_F77_FLAGS CHAMP_LD_FLAGS CHAMP_C CHAMP_CXX
####################### MACHINES ########################################

ifeq ($(hostname),gauss)
  CHAMP_F95_FAST= -zero -r8 -pad -align all -O3 -fpp -ip -extend_source -mtune=core2 -march=core2 -xT 
  CHAMP_F95_PROF= -zero -r8 -pad -align all -O3 -fpp -pg -extend_source -mtune=core2 -march=core2 -xT
  CHAMP_F95_DEBUG=-zero -r8 -pad -align all -O0 -fpp -ip -extend_source -mtune=core2 -march=core2 -xT -check all -check nooutput_conversion -debug extended -debug-parameters all -g -traceback -error_limit 1 -DDEBUG
endif

# Theory Center's linux cluster
# ifeq ($(hostname),linuxlogin1.tc.cornell.edu)
ifeq ($(findstring linuxlogin,$(hostname)), linuxlogin)
 CHAMP_MPIF95=mpif90
 CHAMP_LD_MPI=mpif90
endif

# OSC Itanium cluster, requires Intel compiler >9.0
ifeq ($(hostname),ipf-login1)
  CHAMP_MPIF95=mpif90
  LAPACK=-L/usr/local/mkl-7.0.1.6/mkl701/lib/64 -lmkl_lapack -lmkl_ipf -lguide -lpthread
  BLAS=-L/usr/local/mkl-7.0.1.6/mkl701/lib/64 -lmkl_ipf -lguide -lpthread
endif

# OSC Pentium IV cluster, requires Intel compiler >9.0
ifeq ($(hostname),piv-login1)
  CHAMP_MPIF95=mpif90
  LAPACK=-L/usr/local/mkl-7.0.17/mkl70/lib/32 -lmkl_lapack -lmkl_ia32 -lguide -lpthread -Vaxlib
  BLAS=-L/usr/local/mkl-7.0.17/mkl70/lib/32 -lmkl_ia32 -lguide -lpthread
endif

# OSC Opteron cluster
ifeq ($(hostname),opt-login01.osc.edu)
# Serial (Intel compiler), requires ACML for Intel module
# module load acml-intel

# Parallel (Intel compiler), requires ACML & MPI for Intel
# module load acml-intel
# module swap mpi mvapich-0.9.8-intel

  CHAMP_MPIF95 = mpif77 -fc=ifort
  CHAMP_MPIC = mpicc -cc=icc
  CHAMP_LD_MPI = mpif77 -fc=ifort
  CHAMP_LD_FAST=-O3 -align all

# Serial (Portland compiler), requires ACML module
# module load acml
# CHAMP_F95 = pgf95
# CHAMP_C = pgcc
# CHAMP_LD = pgf95
# CHAMP_F77_FAST = -Mpreprocess -Mextend -O2 -tp amd64e
# CHAMP_F95_FAST = -Mpreprocess -O2 -tp amd64 -DPGI
# CHAMP_C_FAST = -DUNDERSCORE -O2 -tp amd64e
# CHAMP_LD_FAST = -O2 -tp amd64e

# Parallel (Portland compiler), requires ACML module
# module load acml
# CHAMP_MPIF95 = mpif90
# CHAMP_MPIC = mpicc
# CHAMP_LD_MPI = mpif90
# CHAMP_F77_MPI_FLAGS = -Mpreprocess -Mextend -DMPI -O2 -tp amd64e
# CHAMP_F95_MPI_FLAGS = -Mpreprocess -DMPI -O2 -tp amd64e -DPGI
# CHAMP_C_MPI_FLAGS = -DMPI -DUNDERSCORE -O2 -tp amd64e

  LAPACK=${ACML}
  BLAS=${ACML}
endif

# Richard's Cornell machine
ifeq ($(hostname),kyra.ccmr.cornell.edu)
 LAPACK=-L/opt/intel/mkl_serial_8.1/lib/32/ -lmkl_lapack
 BLAS=-L/opt/intel/mkl_serial_8.1/lib/32/ -lmkl_ia32 -lguide -lpthread
endif

# Machines at OSU
ifeq ($(hostname),devon)
 LAPACK=-L${MKL_HOME}/lib/32 -lmkl_lapack
 BLAS=-L${MKL_HOME}/lib/32 -lmkl_ia32 -lguide -lpthread
 CHAMP_C=icc
endif
ifeq ($(hostname),kunoy)
 LAPACK=-L${MKL_HOME}/lib/32 -lmkl_lapack
 BLAS=-L${MKL_HOME}/lib/32 -lmkl_ia32 -lguide -lpthread
endif
ifeq ($(hostname),banks)
 LAPACK=-L${MKL_HOME}/lib/32 -lmkl_lapack
 BLAS=-L${MKL_HOME}/lib/32 -lmkl_ia32 -lguide -lpthread
endif
ifeq ($(hostname),pico)
 LAPACK=-L${MKL_HOME}/lib/32 -lmkl_lapack
 BLAS=-L${MKL_HOME}/lib/32 -lmkl_ia32 -lguide -lpthread
endif
ifeq ($(hostname),vega)
 LAPACK=-L${MKL_HOME}/lib/32 -lmkl_lapack
 BLAS=-L${MKL_HOME}/lib/32 -lmkl_ia32 -lguide -lpthread
endif
ifeq ($(hostname),naxos)
 LAPACK=-L${MKL_HOME}/lib/32 -lmkl_lapack
 BLAS=-L${MKL_HOME}/lib/32 -lmkl_ia32 -lguide -lpthread
endif
ifeq ($(hostname),samos)
 LAPACK=-L${MKL_HOME}/mkl701/lib/64 -lmkl_lapack
 BLAS=-L${MKL_HOME}/mkl701/lib/64 -lmkl_ia64 -lguide -lpthread
endif

# Argonne Blue-Gene BG/L, login1
ifeq ($(hostname),login1)

# serial
  CHAMP_F77 = xlf
  CHAMP_F77_FAST = -O5 -qarch=440 -qtune=440 -qsuffix=cpp=f -WF,-DUNDERSCORE -qfixed=132 -Ifit -Ivmc -Ivmc/MPI -Idmc -Idmc/dmc_elec -Idmc/dmc_elec/MPI -qsuppress=1512-039 -qsuppress=1512-047
  CHAMP_F95 = xlf95
  CHAMP_F95_FAST = -O5 -qarch=440 -qtune=440 -qsuffix=cpp=f90 -qsuppress=1512-039 -qsuppress=1512-047
  CHAMP_C = xlc
  CHAMP_C_FAST = -O5
  CHAMP_LD = xlf95
  CHAMP_LD_FAST =

# serial debug
  CHAMP_F77_DEBUG = -C -g -qsigtrap -qlinedebug -qsuffix=cpp=f -WF,-DDEBUG,-DUNDERSCORE -qfixed=132 -Ifit -Ivmc -Ivmc/MPI -Idmc -Idmc/dmc_elec -Idmc/dmc_elec/MPI -qsuppress=1512-039 -qsuppress=1512-047
  CHAMP_F95_DEBUG = -C -g -qsigtrap -qlinedebug -qsuffix=cpp=f90 -WF,-DDEBUG -qsuppress=1512-039 -qsuppress=1512-047
  CHAMP_C_DEBUG =
  CHAMP_LD_DEBUG =

# MPI debug
  CHAMP_MPIF95 = mpif90.ibm
  CHAMP_F77_MPI_FLAGS = -C -g -qsigtrap -qlinedebug -qflttrap=enable:inexact:invalid:overflow:underflow:zerodivide -qarch=440 -qtune=440 -qsuffix=cpp=f -WF,-DMPI -qfixed=132 -Ifit -Ivmc -Ivmc/MPI -Idmc -Idmc/dmc_elec -Idmc/dmc_elec/MPI -qsuppress=1512-039 -qsuppress=1512-047
  CHAMP_F95_MPI_FLAGS = -C -g -qsigtrap -qlinedebug -qflttrap=enable:inexact:invalid:overflow:underflow:zerodivide -qarch=440 -qtune=440 -qsuffix=cpp=f90  -WF,-DMPI -qsuppress=1512-039 -qsuppress=1512-047
  CHAMP_MPIC = mpicc.ibm
  CHAMP_C_MPI_FLAGS =  -C -g -qsigtrap -qlinedebug -qflttrap=enable:inexact:invalid:overflow:underflow:zerodivide
  CHAMP_LD_MPI = mpif90.ibm

# MPI
  CHAMP_MPIF95 = mpif90.ibm
  CHAMP_F77_MPI_FLAGS = -O5 -qarch=440 -qtune=440 -qsuffix=cpp=f -WF,-DMPI,-DUNDERSCORE -qfixed=132 -Ifit -Ivmc -Ivmc/MPI -Idmc -Idmc/dmc_elec -Idmc/dmc_elec/MPI -qsuppress=1512-039 -qsuppress=1512-047
  CHAMP_F95_MPI_FLAGS = -O5 -qarch=440 -qtune=440 -qsuffix=cpp=f90  -WF,-DMPI -qsuppress=1512-039 -qsuppress=1512-047
  CHAMP_MPIC = mpicc.ibm
  CHAMP_C_MPI_FLAGS = -O5
  CHAMP_LD_MPI = mpif90.ibm
endif

# Jaguar at NCCS Oak Ridge
ifeq ($(findstring jaguar,$(hostname)), jaguar)

# Portland compiler (requires ACML module?)
## module load acml

# Serial compilation
# the following configuration compiles but the code segm. faults
# CHAMP_F95 = pgf95
# CHAMP_C = pgcc
# CHAMP_LD = pgf95
# CHAMP_F77_FAST = -Mpreprocess -Mextend -O2 -tp amd64e
# CHAMP_F95_FAST = -Mpreprocess -O2 -tp amd64 -DPGI
# CHAMP_C_FAST = -DUNDERSCORE -O2 -tp amd64e
# CHAMP_LD_FAST = -O2 -tp amd64e

# MPI compilation
# CHAMP_MPIF95 = mpif90
# CHAMP_MPIC = mpicc
# CHAMP_LD_MPI = mpif90
# CHAMP_F77_MPI_FLAGS = -Mpreprocess -Mextend -DMPI -O2 -tp amd64e
# CHAMP_F95_MPI_FLAGS = -Mpreprocess -DMPI -O2 -tp amd64e -DPGI
# CHAMP_C_MPI_FLAGS = -DMPI -DUNDERSCORE -O2 -tp amd64e

#  LAPACK=${ACML}
#  BLAS=${ACML}

# Pathscale compiler
# must unload pgi and load pathscale and acml first:
# module swap PrgEnv-pgi PrgEnv-pathscale && module load acml
# The "-Wl,-z,muldefs" tells it to not stop if it encounters multiple definitions of e.g. __exp

# Serial compilation
 CHAMP_F95 = ftn -target=linux
 CHAMP_C = cc -target=linux
 CHAMP_F77_FAST = -cpp -DPATHSCALE -O2 -r8 -extend-source -zerouv
 CHAMP_F95_FAST = -cpp -DPATHSCALE -O2 -r8 -zerouv
 CHAMP_C_FAST =  -DPATHSCALE -DUNDERSCORE -O2
 CHAMP_LD = ftn -target=linux -Wl,-z,muldefs
 CHAMP_LD_FAST = -O2

# MPI compilation
 CHAMP_MPIF95 = ftn -target=linux
 CHAMP_MPIC = cc -target=linux
 CHAMP_F77_MPI_FLAGS = -cpp -DPATHSCALE -DMPI -O2 -r8 -extend-source -zerouv
 CHAMP_F95_MPI_FLAGS = -cpp -DPATHSCALE -DMPI -O2 -r8 -zerouv
 CHAMP_C_MPI_FLAGS = -DPATHSCALE -DMPI -DUNDERSCORE -O2
 CHAMP_LD_MPI = ftn -target=linux -O2 -Wl,-z,muldefs

# acml has both the LAPACK and the BLAS
 LAPACK=-lacml
 BLAS=

endif

# clastos in Paris
ifeq ($(hostname),clastos)
# CHAMP_C=icc
 CHAMP_C=/usr/local/bin/mpicc_64
# CHAMP_CXX=icpc
 CHAMP_CXX=/usr/local/bin/mpicxx_64
 CHAMP_F95=/usr/local/bin/mpif90_64
 CHAMP_F95_FAST=-zero -r8 -pad -align all -O3 -ip -diag-disable vec -fpp -DNOEINSPLINE
 CHAMP_F95_DEBUG=-zero -r8 -pad -align all -O0 -fpp -ip -check all -check nooutput_conversion -debug extended -debug-parameters all -g -traceback -error_limit 1 -DDEBUG -DNOEINSPLINE
 EINSPLINE=
 CHAMP_MPIF95=/usr/local/bin/mpif90_64
 CHAMP_MPIC=/usr/local/bin/mpicc_64
endif

# NASA Ames Columbia Itanium cluster
ifeq ($(hostname),cfe1)
  CHAMP_MPIF95=ifort
  CHAMP_LD_MPI=ifort
  CHAMP_LD_FAST=-O3 -align all
  CHAMP_LD_END_MPI=-nothread -lmpi -lpthread
endif

#jasmine at cornell
ifeq ($(hostname),jasmine)
  CHAMP_C=gcc
  CHAMP_CXX=g++
  CHAMP_MPIC=mpicc
  CHAMP_F95=gfortran
  CHAMP_MPIF95=mpif90
  CHAMP_F95_FAST=-finit-local-zero -O3 -fdefault-real-8 -ffree-line-length-none -x f95-cpp-input -Wall
  CHAMP_F77_FAST=-finit-local-zero -O3 -fdefault-real-8 -ffixed-line-length-132 -x f77-cpp-input -Wall
  CHAMP_LD=gfortran
# CHAMP_LD_FLAGS=-static
  CHAMP_LD_FLAGS=-O3
  CHAMP_LD_MPI=mpif90
endif

# AMD Opteron cluster with Pathscale compiler on slid.fysik at Lyngby, Denmark
ifeq ($(findstring slid.fysik.dtu.dk,$(hostname)), slid.fysik.dtu.dk)

# Serial compilation
#CHAMP_F95 = ftn -target=linux
 CHAMP_F95 = pathf90
#CHAMP_C = cc -target=linux
 CHAMP_C = pathf90
 CHAMP_F77_FAST = -cpp -DPATHSCALE -O2 -r8 -extend-source -zerouv
 CHAMP_F95_FAST = -cpp -DPATHSCALE -O2 -r8 -zerouv
 CHAMP_C_FAST =  -DPATHSCALE -DUNDERSCORE -O2
 CHAMP_LD = pathf90 -Wl,-z,muldefs
 CHAMP_LD_FAST = -O2

# MPI compilation
 CHAMP_MPIF95 = pathf90
 CHAMP_MPIC = pathf90
 CHAMP_F77_MPI_FLAGS = -cpp -DPATHSCALE -DMPI -O2 -r8 -extend-source -zerouv
 CHAMP_F95_MPI_FLAGS = -cpp -DPATHSCALE -DMPI -O2 -r8 -zerouv
 CHAMP_C_MPI_FLAGS = -DPATHSCALE -DMPI -DUNDERSCORE -O2
 CHAMP_LD_MPI = pathf90 -O2 -Wl,-z,muldefs

# acml has both the LAPACK and the BLAS
 LAPACK=-L/opt/acml-3.6.0/pathscale64/lib -lacml
 BLAS=

endif

# AMD Opteron cluster with Intel compiler on school1.fysik at Lyngby, Denmark
ifeq ($(findstring school,$(hostname)), school)

#CHAMP_F77_FAST=-zero -extend_source -w -r8 -O3 -pad -ip -fpp -mtune=core2 -march=core2 -xT
#CHAMP_F77_FLAGS=$(CHAMP_F77_FAST)
#CHAMP_F95_FAST=-O3 -ip -align all -fpp -mtune=core2 -march=core2 -xT
#CHAMP_F95_FLAGS=$(CHAMP_F95_FAST)
#CHAMP_LD_FAST=-O3 -align all -mtune=core2 -march=core2 -xT
#CHAMP_LD_FLAGS=$(CHAMP_LD_FAST)
#CHAMP_MPIC=mpicc
#CHAMP_MPIF95=mpif90
#CHAMP_MPIF77=mpif90
#CHAMP_LD_MPI=mpif90
#CHAMP_F77_MPI_FLAGS=-zero -extend_source -w -r8 -O3 -pad -ip -fpp -DMPI -mtune=core2 -march=core2 -xT
#CHAMP_F95_MPI_FLAGS=-O3 -ip -align all -fpp -DMPI -mtune=core2 -march=core2 -xT

CHAMP_F95=ifort
CHAMP_MPIF95=mpif77

CHAMP_F77_FAST=-zero -extend_source -w -r8 -O3 -pad -ip -fpp
CHAMP_F77_IPO=-zero -extend_source -w -r8 -O3 -pad -ipo -fpp
CHAMP_F77_DEBUG=-zero -extend_source -r8 -check all -check nooutput_conversion -debug extended -debug-parameters all -g -traceback -error_limit 1 -fpp -DDEBUG
CHAMP_F77_PROF=-zero -extend_source -w -r8 -O3 -pad -pg -fpp
CHAMP_F77_MPI_FLAGS=-zero -extend_source -w -r8 -O3 -pad -ip -fpp -DMPI
CHAMP_F77_MPI_FLAGSDEBUG=-zero -extend_source -r8 -check all -check nooutput_conversion -debug extended -debug-parameters all -g -traceback -error_limit 1 -fpp -DMPI -DDEBUG
CHAMP_F77_FLAGS=$(CHAMP_F77_FAST)

CHAMP_F95_FAST=-O3 -ip -align all -fpp
CHAMP_F95_IPO=-O3 -ipo -align all -fast -fpp
CHAMP_F95_DEBUG=-check all -check nooutput_conversion -debug extended -debug-parameters all -g -traceback -error_limit 1 -fpp -DDEBUG
CHAMP_F95_PROF=-O3 -pg -fpp
CHAMP_F95_MPI_FLAGS=-O3 -ip -align all -fpp -DMPI
CHAMP_F95_MPI_FLAGSDEBUG=-check all -check nooutput_conversion -debug extended -debug-parameters all -g -traceback -error_limit 1 -fpp -DMPI -DDEBUG
CHAMP_F95_FLAGS=$(CHAMP_F95_FAST)

# Linking  ------------------------------------------------------------------

CHAMP_LD=ifort
CHAMP_LD_MPI=mpif77

CHAMP_LD_FAST=-O3 -align all
CHAMP_LD_IPO=-O3 -ipo -align all -fast
CHAMP_LD_DEBUG=
CHAMP_LD_PROF=-O3 -pg
CHAMP_LD_FLAGS=$(CHAMP_LD_FAST)

CHAMP_LD_END=
#CHAMP_LD_END_MPI=-lmpi -lpthread
CHAMP_LD_END_MPI=

# acml has both the LAPACK and the BLAS
 LAPACK=-L/opt/acml-3.6.0/ifort64/lib -lacml
 BLAS=

endif

# Julich BlueGene P
ifeq ($(hostname),jugene1)

# MPI
  CHAMP_MPIF95 = mpixlf2003
  CHAMP_F77_MPI_FLAGS = -O3 -qstrict -qarch=450 -qtune=450 -qsuffix=cpp=f -WF,-DMPI,-DUNDERSCORE -qfixed=132 -Ifit -Ivmc -Ivmc/MPI -Idmc -Idmc/dmc_elec -Idmc/dmc_elec/MPI -qsuppress=1512-039 -qsuppress=1512-047
  CHAMP_F95_MPI_FLAGS = -O3 -qstrict -qarch=450 -qtune=450 -qsuffix=cpp=f90  -WF,-DMPI -qsuppress=1512-039 -qsuppress=1512-047
  CHAMP_MPIC = mpixlc
  CHAMP_C_MPI_FLAGS = -O3 -qstrict
endif
