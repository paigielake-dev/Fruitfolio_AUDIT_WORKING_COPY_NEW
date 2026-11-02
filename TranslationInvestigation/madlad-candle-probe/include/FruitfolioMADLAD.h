#ifndef FRUITFOLIO_MADLAD_H
#define FRUITFOLIO_MADLAD_H
#ifdef __cplusplus
extern "C" {
#endif
/* Serialize access. Root must contain verified official model/config/tokenizer.
   Returned strings are caller-owned and released with free_string. Never treat
   generated output as medically validated merely because ok is true. */
void *fruitfolio_madlad_open(const char *root, char **error);
char *fruitfolio_madlad_translate(void *handle, const char *prompt);
void fruitfolio_madlad_close(void *handle);
void fruitfolio_madlad_free_string(char *value);
#ifdef __cplusplus
}
#endif
#endif
