#include <stdio.h>
#include "FruitfolioMADLAD.h"
int main(int argc,char **argv){
 if(argc!=2)return 2;
 char *error=0;void *runtime=fruitfolio_madlad_open(argv[1],&error);
 if(!runtime){fprintf(stderr,"%s\n",error?error:"null error");fruitfolio_madlad_free_string(error);return 1;}
 char *result=fruitfolio_madlad_translate(runtime,"<2es> This is educational information, not medical advice.");
 if(!result){fruitfolio_madlad_close(runtime);return 3;}
 puts(result);fruitfolio_madlad_free_string(result);
 result=fruitfolio_madlad_translate(runtime,"<2es> The result is 2.5 ng/mL.");
 if(!result){fruitfolio_madlad_close(runtime);return 4;}
 puts(result);fruitfolio_madlad_free_string(result);fruitfolio_madlad_close(runtime);return 0;
}
