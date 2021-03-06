#include <stdio.h>
#define DEBUGPRINT 0
__global__ void compute_grid_h_kernel( double *gridh, double *xm1, double *ym1, double *zm1, int nelt, int lx1, int ly1, int lz1, int if3d,  int nnel,int lxy, int lxyz  ){    
	int id = blockIdx.x*blockDim.x+threadIdx.x;
	if(id<nnel){

		int ix= id % lx1;
		int iy= (id/lx1)%ly1;
		int iz = (id / (lxy))%lz1;
		int e =  id / (lxyz);
		int km1,kp1,izm,izp;
                int x1,x2,x3,x4,x5,x6,y1,y2,y3,y4,y5,y6,z1,z2,z3,z4,z5,z6;
                double a1,a2,a3,b1,b2,b3,c1,c2,c3,d1,d2,d3;
		if (if3d) {
			km1=iz-1;
			kp1=iz+1;
			izm=km1;
			if (km1 < 1){ izm=iz;}
			izp=kp1;
			if (kp1 > lz1) {izp=iz;}
		}
		else {
			izm=iz;
			izp=iz;
		}

	        int jm1=iy-1;
		int jp1=iy+1;
		int iym=jm1;
		if (jm1 < 1) {iym=iy;}
		int iyp=jp1;
		if (jp1 > ly1) {iyp=iy;}

		int im1=ix-1;
		int ip1=ix+1;
		int ixm=im1;
		if (im1 < 1){ ixm=ix;}
		int ixp=ip1;
		if (ip1 > lx1) {ixp=ix;}
		x1 = xm1[e*lxyz+iz*lxy+iy*lx1+ixm];// possible  optimizations for array reads . adeesha
		x2 = xm1[e*lxyz+iz*lxy+iy*lx1+ixp];
		x3 = xm1[e*lxyz+iz*lxy+iym*lx1+ix];
		x4 = xm1[e*lxyz+iz*lxy+iyp*lx1+ix];
		x5 = xm1[e*lxyz+izm*lxy+iy*lx1+ix];
		x6 = xm1[e*lxyz+izp*lxy+iy*lx1+ix];
		y1 = ym1[e*lxyz+iz*lxy+iy*lx1+ixm];
		y2 = ym1[e*lxyz+iz*lxy+iy*lx1+ixp];
		y3 = ym1[e*lxyz+iz*lxy+iym*lx1+ix];
		y4 = ym1[e*lxyz+iz*lxy+iyp*lx1+ix];
		y5 = ym1[e*lxyz+izm*lxy+iy*lx1+ix];
		y6 = ym1[e*lxyz+izp*lxy+iy*lx1+ix];
		z1 = zm1[e*lxyz+iz*lxy+iy*lx1+ixm];
		z2 = zm1[e*lxyz+iz*lxy+iy*lx1+ixp];
		z3 = zm1[e*lxyz+iz*lxy+iym*lx1+ix];
		z4 = zm1[e*lxyz+iz*lxy+iyp*lx1+ix];
		z5 = zm1[e*lxyz+izm*lxy+iy*lx1+ix];
		z6 = zm1[e*lxyz+izp*lxy+iy*lx1+ix];
		a1=x2-x1;
		a2=y2-y1;
		a3=z2-z1;
		b1=x4-x3;
		b2=y4-y3;
		b3=z4-z3;
		c1=x6-x5;
		c2=y6-y5;
		c3=z6-z5;
		double fact;
		if (if3d) {
			fact=0.125; // h doesn't reach into corners of neighboring elements
			if (ixp==ix || ixm==ix){ fact=2.0*fact;}
			if (iym==iy || iyp==iy) {fact=2.0*fact;}
			if (izm==iz||izp==iz) {fact=2.0*fact;}
			//call cross(d,a,b);
			// cartesian vector cross product in gpu
                        d1 = a2*b3 - a3*b2;
      			d2 = a3*b1 - a1*b3;
      			d3 = a1*b2 - a2*b1;
                        // vector dot product to get sum
                        double sum = c1*d1+c2*d2+c3*d3;
			gridh[e*lxyz+iz*lxy+iy*lx1+ix]=fact*sum;
			gridh[e*lxyz+iz*lxy+iy*lx1+ix]=pow(fabs(gridh[e*lxyz+iz*lxy+iy*lx1+ix]),(1.0/3.0));
		}
		else{
			fact=0.25;
			if (ixp==ix||ixm==ix) fact=2.0*fact;
			if (iym==iy||iyp==iy) fact=2.0*fact;
			gridh[e*lxyz+iz*lxy+iy*lx1+ix]=sqrtf(fact*fabs(a1*b2-a2*b1));
		}





	}
}


extern "C" void compute_grid_h_gpu_wrapper_(int *glbblockSize1,double *d_gridh, double *d_xm1, double *d_ym1, double *d_zm1, int *nelt, int *lx1, int *ly1, int *lz1, int *if3d){
#ifdef DEBUGPRINT
cudaDeviceSynchronize();
 cudaError_t code1 = cudaPeekAtLastError();

printf("CUDA: Start compute_grid_h_gpu_wrapper cuda status: %s\n",cudaGetErrorString(code1));

printf("CUDA: Start compute_grid_h_gpu_wrapper values glbblockSize1=%d, nelt=%d,lx1=%d,ly1=%d,lz1=%d,if3d=%d\n",glbblockSize1[0],nelt[0],lx1[0],ly1[0],lz1[0],if3d[0]);
#endif
	int blockSize = glbblockSize1[0], gridSize;
	int lxy=lx1[0]*ly1[0];
	int lxyz=lxy*lz1[0];
	int nnel=nelt[0]*lxyz;
	gridSize = (int)ceil((float)nnel/blockSize);
#ifdef DEBUGPRINT
	printf("CUDA:  compute_grid_h_gpu_wrapper grid size = %d, block size = %d \n",gridSize,blockSize);
#endif
	compute_grid_h_kernel<<<gridSize, blockSize>>>(d_gridh, d_xm1, d_ym1, d_zm1, nelt[0],lx1[0],ly1[0],lz1[0],if3d[0],nnel,lxy,lxyz);
#ifdef DEBUGPRINT
cudaDeviceSynchronize();
 cudaError_t code2 = cudaPeekAtLastError();

printf("CUDA: End compute_grid_h_gpu_wrapper cuda status: %s\n",cudaGetErrorString(code2));

#endif
 	/*printf(" $$$ compute_grid_h_gpu_wrapper check start ");
        for(int b=0;b<10;b++){
                printf("d_gridh[%d] = %lf \n",b,d_gridh[b]);
        }
        printf(" $$$ compute_grid_h_gpu_wrapper check End ");*/



}

__global__ void compute_mesh_h_kernel( double *meshh, double *xm1, double *ym1, double *zm1, int nelt, int lx1, int ly1, int lz1, int if3d, double rp , int ncrn, int lxy,  int lxyz){
        int id = blockIdx.x*blockDim.x+threadIdx.x;
        if(id<nelt){
                int ic1,ic2;
                //int ic2= id % ncrn;
                //int ic1= (id/ncrn)%ncrn;
                int e =  id;
                int km1,kp1,izm,izp;
               
		double xcrn[8],ycrn[8],zcrn[8];
			
               	int k1=1;
		int k2= lz1;
 		int j1=1;
		int j2= ly1;
		int i1=1;
		int i2= lx1;

		xcrn[0] = xm1[e*lxyz];
		xcrn[1] = xm1[e*lxyz+lx1-1];
		xcrn[2] = xm1[e*lxyz+(ly1-1)*lx1];
		xcrn[3] = xm1[e*lxyz+(ly1-1)*lx1+lx1-1];
		ycrn[0] = ym1[e*lxyz];
		ycrn[1] = ym1[e*lxyz+lx1-1];
		ycrn[2] = ym1[e*lxyz+(ly1-1)*lx1];
		ycrn[3]= ym1[e*lxyz+(ly1-1)*lx1+lx1-1];
		if (if3d) {
			xcrn[4] = xm1[e*lxyz+(lz1-1)*lxy];
			xcrn[5] = xm1[e*lxyz+(lz1-1)*lxy+lx1-1];
			xcrn[6] = xm1[e*lxyz+(lz1-1)*lxy+(ly1-1)*lx1];
			xcrn[7] = xm1[e*lxyz+(lz1-1)*lxy+(ly1-1)*lx1+lx1-1];
			ycrn[4] = ym1[e*lxyz+(lz1-1)*lxy];
			ycrn[5] = ym1[e*lxyz+(lz1-1)*lxy+lx1-1];
			ycrn[6] = ym1[e*lxyz+(lz1-1)*lxy+(ly1-1)*lx1];
			ycrn[7] = ym1[e*lxyz+(lz1-1)*lxy+(ly1-1)*lx1+lx1-1];
			zcrn[0] = zm1[e*lxyz];
			zcrn[1] = zm1[e*lxyz+lx1-1];
			zcrn[2] = zm1[e*lxyz+(ly1-1)*lx1];
			zcrn[3] = zm1[e*lxyz+(ly1-1)*lx1+lx1-1];
			zcrn[4] = zm1[e*lxyz+(lz1-1)*lxy];
			zcrn[5] = zm1[e*lxyz+(lz1-1)*lxy+lx1-1];
			zcrn[6] = zm1[e*lxyz+(lz1-1)*lxy+(ly1-1)*lx1];
			zcrn[7] = zm1[e*lxyz+(lz1-1)*lxy+(ly1-1)*lx1+lx1-1];
                }
                double dist = 10e+36;
                for (ic1 = 0 ; ic1<ncrn;ic1++){
			for (ic2 = 0; ic2<ncrn; ic2++){
				if(ic2 !=ic1){
                                	double txcrn = xcrn[ic2]-xcrn[ic1];
					double tycrn = ycrn[ic2]-ycrn[ic1];
					double tzcrn = zcrn[ic2]-zcrn[ic1];	
					double dtmp = txcrn*txcrn+tycrn*tycrn+tzcrn*tzcrn;
					double sqrtdtmp = sqrtf(dtmp) ;
					if(sqrtdtmp<dist){
						dist =sqrtdtmp;
					}
				}
			}
		}
		/*if(id==0){
			for(int aa=0;aa<2;aa++){
				printf("$$$ print from cuda xm1 = %lf, ym1 =%lf zm1 = %lf \n",xm1[aa],ym1[aa],zm1[aa]);
				printf("$$$ print from cuda xcrn = %lf, ycrn =%lf zcrn = %lf \n",xcrn[aa],ycrn[aa],zcrn[aa]);
			}
			printf("$$$ print from cuda dist = %lf, rp=%lf \n",dist,rp );
		}*/
		meshh[e]= dist*rp;



        }
}



extern "C" void compute_mesh_h_gpu_wrapper_(int *glbblockSize2,double *d_meshh, double *d_xm1, double *d_ym1, double *d_zm1, int *nelt, int *lx1, int *ly1, int *lz1, int *if3d, double *rp, int *ncrn){
#ifdef DEBUGPRINT
cudaDeviceSynchronize();
 cudaError_t code1 = cudaPeekAtLastError();

printf("CUDA: Start compute_mesh_h_gpu_wrapper cuda status: %s\n",cudaGetErrorString(code1));

printf("CUDA: Start compute_mesh_h_gpu_wrapper values nelt=%d,lx1=%d,ly1=%d,lz1=%d,if3d=%d rp=%lf,ncrn=%d \n",nelt[0],lx1[0],ly1[0],lz1[0],if3d[0],rp[0],ncrn[0]);
#endif

        int blockSize = glbblockSize2[0], gridSize;
        gridSize = (int)ceil((float)nelt[0]/blockSize);
	int lxy=lx1[0]*ly1[0];
	int lxyz=lz1[0]*lxy;
        compute_mesh_h_kernel<<<gridSize, blockSize>>>(d_meshh, d_xm1, d_ym1, d_zm1, nelt[0],lx1[0],ly1[0],lz1[0],if3d[0],rp[0],ncrn[0],lxy,lxyz);
#ifdef DEBUGPRINT
cudaDeviceSynchronize();
cudaError_t code2 = cudaPeekAtLastError();

printf("CUDA: End compute_mesh_h_gpu_wrapper cuda status: %s\n",cudaGetErrorString(code2));

#endif
	/*printf(" $$$ compute_mesh_h_gpu_wrapper check start ");
        for(int b=0;b<10;b++){
                printf("d_meshh[%d] = %lf \n",b,d_gridh[b]);
        }
        printf(" $$$ compute_mesh_h_gpu_wrapper check End ")*/

}

