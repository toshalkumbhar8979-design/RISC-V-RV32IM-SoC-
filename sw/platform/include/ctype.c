int isprint(int c){ return (c>=0x20 && c<0x7f); }
int isspace(int c){ return (c==' '||c=='\t'||c=='\n'||c=='\r'||c=='\f'||c=='\v'); }
int isalpha(int c){ return ((c>='a'&&c<='z')||(c>='A'&&c<='Z')); }
int isdigit(int c){ return (c>='0'&&c<='9'); }
int isalnum(int c){ return isalpha(c)||isdigit(c); }
int isupper(int c){ return (c>='A'&&c<='Z'); }
int islower(int c){ return (c>='a'&&c<='z'); }
int toupper(int c){ return (c>='a'&&c<='z')?c-32:c; }
int tolower(int c){ return (c>='A'&&c<='Z')?c+32:c; }
int strcasecmp(const char*a,const char*b)
{ while(*a&&*b){int d=(unsigned char)tolower(*a)-(unsigned char)tolower(*b); if(d)return d; a++;b++;}
  return (int)((unsigned char)tolower(*a)-(unsigned char)tolower(*b)); }
int strncasecmp(const char*a,const char*b,unsigned long n)
{ while(n&&*a&&*b){int d=(unsigned char)tolower(*a)-(unsigned char)tolower(*b); if(d)return d; a++;b++;n--;}
  return n?(int)((unsigned char)tolower(*a)-(unsigned char)tolower(*b)):0; }
