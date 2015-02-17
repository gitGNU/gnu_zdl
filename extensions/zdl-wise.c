/* ZigzagDownLoader (ZDL) 
 *
 * This program is free software: you can redistribute it and/or modify it  
 * under the terms of the GNU General Public License as published  
 * by the Free Software Foundation; either version 3 of the License, 
 * or (at your option) any later version. 
 *
 * This program is distributed in the hope that it will be useful, 
 * but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. 
 *
 * You should have received a copy of the GNU General Public License  
 * along with this program. If not, see http://www.gnu.org/licenses/. 
 *
 * Copyright (C) 2011: Gianluca Zoni (zoninoz) <zoninoz@inventati.org>
 *
 * For information or to collaborate on the project:        
 * https://savannah.nongnu.org/projects/zdl
 *
 * Gianluca Zoni (author)
 * http://inventati.org/zoninoz
 * zoninoz@inventati.org
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>


int main (int argc, char *argv[]){
  char *w = argv[1];
  char *i = argv[2];
  char *s = argv[3];
  char *e = argv[4];

  int j = 0;
  int m = 0;
  int n = 0;
  
  size_t l = strlen(w)+strlen(i)+strlen(s)+strlen(e);
  char *D = malloc(l*sizeof(char));
  char *F = malloc(l*sizeof(char));
  
  while (1) {
    if (j < 5) {
      F[m++] = w[j];
    } else if (j < strlen(w)) {
      D[n++] = w[j];
    }

    if (j < 5) {
      F[m++] = i[j];
    } else if (j < strlen(i)) {
      D[n++] = i[j];
    }

    if (j < 5) {
      F[m++] = s[j];
    } else if (j < strlen(s)) {
      D[n++] = s[j];
    }
    j++;

    if (l == strlen(D)+strlen(F)+strlen(e))
      break;
  }
  
  int c;
  int J = 0;
  char *z;

  for (j = 0; j < strlen(D); j += 2) {
    m = -1;
    c = (int) F[J]; 
    if (c%2)
      m = 1;
    char v[] = { D[j], D[j+1], '\0' };

    n = strtol(v, &z, 36);
    if (*z == '\0'){
      printf ("%c", n-m); 
    }

    J++;
    if (J >= strlen(F))
      J = 0;
  }
  return 0;
}
