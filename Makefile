MAKEFLAGS += --no-builtin-rules --no-builtin-variables


FC := gfortran
LD := $(FC)


MAIN := wls2f90
MAINSRC := $(MAIN).f90
MAINOBJ := $(patsubst %.f90, %.o, $(MAINSRC))


SRCS := convert.f90 share.f90
OBJS := $(patsubst %.f90, %.o, $(SRCS))
INCLUDEDIR := include
FCFLAGS += -I$(INCLUDEDIR)


RM := rm -rf $(MAIN) $(MAINOBJ) $(OBJS) $(INCLUDEDIR)


.PHONY: all clean


all: $(MAIN)


$(MAIN): $(MAINOBJ) $(OBJS)
	$(LD) -o $@ $^


$(MAINOBJ): %.o: %.f90
	$(FC) -c $< $(FCFLAGS)


$(OBJS): %.o: %.f90
	mkdir -p $(INCLUDEDIR)
	$(FC) -c $< $(FCFLAGS) -J $(INCLUDEDIR) -I $(INCLUDEDIR)


$(MAINOBJ): $(OBJS)


$(OBJS): $(MAKEFILE_LIST)


convert.o: share.o


clean:
	$(RM)
