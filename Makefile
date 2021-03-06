GCC = 0 
RPI = 0
PORT = 22
HOST = pi-la
NAME = main    
GFX=1
PLATFORM=$(shell uname)

ifeq ($(PLATFORM),Linux)
	GCC = 1
endif

PIROOT = $(HOME)/code/pi/root/


#PASS IN CLANG=path/to/clang++ if default is not working
CLANG = 0

#COMPILER VERSION  

ifeq ($(GCC),1) 
ifeq ($(RPI),1)
   CXX = arm-linux-gnueabihf-g++ -std=c++0x
else
   CXX = g++ -std=c++0x 
endif
else  
ifneq ($(CLANG),0) 
	CXX = $(CLANG) -std=c++11  
else 
	CXX = clang++ -std=c++11  
endif 
	CXX += -arch x86_64
endif
CXX += -O3 -ftemplate-depth-1200  -Wno-switch -Wno-int-to-pointer-cast
AR 	= ar crs 

IPATH = -Ivsr/ 
LDFLAGS =  
#INCLUDES AND LINKS
ifeq ($(RPI),0)  
IPATH += -I/usr/include/ 
LDFLAGS += -Lbuild/lib/ -Lext/glv/build/lib/ -lvsr 
#-lvsr
LDFLAGS += -lm  
else
IPATH += -I$(PIROOT)usr/include
IPATH += -I$(PIROOT)usr/local/include
IPATH += -I$(PIROOT)opt/vc/include
IPATH += -I$(PIROOT)opt/vc/include/interface/vcos/pthreads
IPATH += -I$(PIROOT)opt/vc/include/interface/vmcs_host/linux  
LDFLAGS += -L$(PIROOT)lib
LDFLAGS += -L$(PIROOT)usr/lib
LDFLAGS += -L$(PIROOT)usr/local/lib
LDFLAGS += -L$(PIROOT)opt/vc/lib
LDFLAGS += -lbcm_host
LDFLAGS += -llo
LDFLAGS += -lm
LDFLAGS += -lrt
LDFLAGS += -lstdc++
LDFLAGS += -lvchiq_arm
LDFLAGS += -lvcos
endif

ifeq ($(GFX),1) 
IPATH += -Iext/glv/ -Iext/gfx/ 
ifeq ($(PLATFORM),Linux)
	LDFLAGS += -lGLV -lGLEW -lGLU -lGL -lglut 
else
	LDFLAGS += -lglv -framework OpenGL -framework GLUT 
endif
endif
                           
LDFLAGS := $(LDFLAGS)  

SRC_DIR = src/
INCLUDE_DIR = vsr/
 
VPATH = $(SRC_DIR):\
		$(INCLUDE_DIR) 

EXEC = tests/%.cpp examples/%.cpp

OBJ = vsr_cga3D_op.o vsr_cga3D_draw.o vsr_cga3D_interface.o vsr_cga3D_cubicLattice.o
#vsr_cga3D_interface.o 
#vsr_cga3D_draw.o

OBJ_DIR = build/obj/
LIB_DIR = build/lib/
BIN_DIR = build/bin/

LIB_NAME = vsr
LIB_FILE = libvsr.a

#LDFLAGS += -l$(LIB_NAME)  

$(OBJ_DIR)%.o: %.cpp 
	@echo hey compiling $@ using $< 
	$(CXX) $(IPATH) -c $< -o $@ 

$(LIB_NAME): dir $(addprefix $(OBJ_DIR),$(OBJ)) 
	@echo archiving $@
	$(AR) $(LIB_DIR)$(LIB_FILE) $(addprefix $(OBJ_DIR), $(OBJ))  

FORCE:

.PRECIOUS: $(EXEC)  
 
glv: 
	@echo "glv"
	@echo "building external GUI library GLV . . . if there are errors, make sure you have entered:\n\n"
	@echo "git submodule init"
	@echo "git submodule update\n\n"
	$(MAKE) --no-print-directory -C ext/glv
	#install DESTDIR=../../$(BUILD_DIR)    


$(EXEC): dir glv vsr FORCE 
	@echo Building $@
	$(CXX) -o $(BIN_DIR)$(*F) $@ $(IPATH) $(LDFLAGS)
	@cd $(BIN_DIR) && ./$(*F)

run:
	./$(BIN_DIR)$(NAME) 

deploy:
	scp -P $(PORT) $(BIN_DIR)$(NAME) $(HOST):/tmp 
	ssh -t -p $(PORT) $(HOST) /tmp/$(NAME) 

dir:
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(LIB_DIR)
	@mkdir -p $(BIN_DIR)  

clean:
	@rm -r $(OBJ_DIR)
	@rm -r $(LIB_DIR)
