#include <stdio.h>
#include <string.h>
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
 puts(result);fruitfolio_madlad_free_string(result);
 result=fruitfolio_madlad_translate(runtime,"<2zzz> This must not execute as an untagged translation.");
 if(!result){fruitfolio_madlad_close(runtime);return 5;}
 puts(result);
 int rejected=strstr(result,"\"ok\":false")!=0 && strstr(result,"exact approved tokenizer tag")!=0;
 fruitfolio_madlad_free_string(result);fruitfolio_madlad_close(runtime);return rejected?0:6;
}
