import processing.video.*;

Capture cam;
PImage img;
PImage wywalone;
boolean generowanie=false;
boolean histogram_wejscie=false;
int counter=0;
PImage[] miniaturki= new PImage [10];
int[] hist = new int[256];
int probki=0;
PrintWriter output, outputbinary,zamianabit;
int ile0=0,ile1=0;
boolean entropia=false;
int[] hist_en=new int[256];

void setup()
{
  size(1280, 720);
  frameRate(10000);
  cam = new Capture(this, "pipeline:autovideosrc");;
  cam.start();
  
}

void na_szare()
{
  img=createImage(cam.width,cam.height,RGB);
  img.loadPixels();
  int x = cam.pixels.length;
  for (int i=0; i<x; i++)
  {
    img.pixels[i]=cam.pixels[i];
  }
  img.updatePixels();
  img.filter(GRAY);
  image(img,0,cam.height/2,cam.width/2,cam.height/2);
}

void spr_pixel()
{
  wywalone=createImage(img.width,img.height,RGB);
  wywalone.loadPixels();
  int x = img.pixels.length;
  for (int i=0; i<x; i++)
  {
    if(int(brightness(img.pixels[i]))>2 && int(brightness(img.pixels[i]))<253)
    {
      wywalone.pixels[i]=cam.pixels[i];
    }
    else 
    {
      wywalone.pixels[i]=color(255,0,0);
    }
  }
  wywalone.updatePixels();
  image(wywalone,cam.width/2,0);
}
void binarka(int r)
{
  switch(counter%2)
  {
    case 0:
    {
      if(r%2==0)
      {
        outputbinary.println("0");
        ile0++;
      }
      else 
        {
          outputbinary.println("1");
          ile1++;
        }
      break;
    }
    case 1:
    {
      if(r%2==0)
      {
        outputbinary.println("1");
        ile1++;
      }
      else
      {
        outputbinary.println("0");
        ile0++;
      }
      break;
    }
  }
}
void wybor_zdjec()
{
  miniaturki[counter]=createImage(img.width,img.height,RGB);
  miniaturki[counter].loadPixels();
  int x = img.pixels.length;
  for (int i=0; i<x; i++)
  {
    if(int(brightness(img.pixels[i]))>2 && int(brightness(img.pixels[i]))<253)
    {
      miniaturki[counter].pixels[i]=cam.pixels[i];
      int r=int(red(cam.pixels[i]));
      int g=int(green(cam.pixels[i]));
      int b=int(blue(cam.pixels[i]));
      if(r>2&&r<253)
      {
        hist[r]++;
        binarka(r); 
        probki++;
        output.print(r+",");
      }
      if(g>2&&g<253)
      {
        hist[g]++;
        binarka(g);
        probki++;
        output.print(g+",");
      }
      if(b>2&&b<253)
      {
        hist[b]++;
        binarka(b);
        probki++;
        output.print(b+",");
      }
      
      
      
    }
    else 
    {
      miniaturki[counter].pixels[i]=color(255,0,0);
    }
  }
  miniaturki[counter].updatePixels();
}

void draw()
{
  fill(255);
  background(0);
  if (cam.available() == true) 
  {
    cam.read();
  }
  image(cam, 0, 0,cam.width/2,cam.height/2);
  na_szare();
  spr_pixel();
  rect(1120,620,160,100);
  fill(255,0,0);
  textSize(32);
  text("Generuj ",1140,660);
  text("wartości ",1140,690);
  fill(255);
  textSize(24);
  text(frameRate,20,20);
  if(mouseX>1120 && mouseX<width && mouseY>620 && mouseY<height)
  {
    cursor(HAND);
  }
  else cursor(ARROW);
  if(generowanie)
  {
    if( frameCount %30 ==0)
    {
      wybor_zdjec();
      counter++;
      if(counter==10)
      {
        histogram_wejscie=true;
        generowanie=false;
        output.flush(); 
        output.close();
        outputbinary.flush();
        outputbinary.close();
        zamiana_bit();
        entropia=true;
      }
    }
    
  }
  miniaturki_show();
  if(histogram_wejscie)
  {
    rysuj_histogram_probek_wejsciowych();
    
  }
  if(entropia)
  {
    entrop_zrod=licz_entropie(hist,probki);
    entropia=false;
    entropia_zer_i_jedynaek();
    int k=0;
    for(int i=0; i<256; i++)
    {
      k+=hist_en[i];
    }
    
    entrop_wyj=licz_entropie(hist_en,k)+1;
    hist_wyjscie=true;
    
  }
  if(hist_wyjscie)
  {
    //print("wyjscie");
    rysuj_histogram_wyjscia();
  }
  
  
  
}
void rysuj_histogram_wyjscia()
{
  int histMax = max(hist_en);
  translate(350,480);
  textSize(18);
  text("Histogram wartości wyjściowych",20, 100);
  textSize(24);
  text("Wygenerowanao: "+xcount+" liczb",300,200);
  translate(0,140);
  stroke(255,255,0);
  // Draw half of the histogram (skip every second value)
  for (int i = 0; i < 256; i += 1) 
  {
    // Map i (from 0..img.width) to a location in the histogram (0..255)
    int which = int(map(i, 0, 256, 0, 255));
    // Convert the histogram value to a location between 
    // the bottom and the top of the picture
    int y = int(map(hist_en[which], 0, histMax, 100, 0));
    line(i, 100, i, y);
  }
  translate(0,-140);
}
boolean hist_wyjscie=false;
int xcount=0;

void entropia_zer_i_jedynaek()
{
  String[] lines = loadStrings("zmienione_zera_i_jedynki.txt");
  int x=lines.length/8;
  int count=7;
  
  int licz=0;
  for(int i=0; i<lines.length; i++)
  {
    int y=int(lines[i]);
    licz+=pow(2*y,count);
    count--;
    if(count<0)
    {
      count=7;
      xcount++;
      hist_en[licz]++;
      licz=0;
      
      if(xcount==x)
      {
        break;
      }
    }
    
  }
}
double entrop_zrod=0;
double licz_entropie(int[] his,int probkii)
{
  double suma=0;
  double su=0;
  float[] p = new float[256];
  for(int i=0; i<256; i++)
  {
    p[i]=float(his[i])/float(probkii);
    if(p[i]>0)
    {
      su+=p[i];
      suma+=p[i]*(log(1/p[i])/log(2));
    }
  }
  print(su+" ");
  return suma;
  
  
  
  
}

void zamiana_bit()
{
  zamianabit = createWriter("zmienione_zera_i_jedynki.txt");
  String[] lines = loadStrings("Zera_i_jedynki.txt");
  //print(lines.length);
  int x=int(sqrt(lines.length));
  for(int i=0; i<x; i++)
  {
    for(int j=0; j<x; j++)
    {
      zamianabit.println(lines[i+j*x]);
    }
  }
  zamianabit.flush();
  zamianabit.close();
  
}

public void rysuj_histogram_probek_wejsciowych()
{
  int histMax = max(hist);
  translate(0,480);
  textSize(18);
  text("Histogram wartości źródła",20, 100);
  translate(0,140);
  stroke(255,0,0);
  // Draw half of the histogram (skip every second value)
  for (int i = 0; i < 256; i += 1) 
  {
    // Map i (from 0..img.width) to a location in the histogram (0..255)
    int which = int(map(i, 0, 256, 0, 255));
    // Convert the histogram value to a location between 
    // the bottom and the top of the picture
    int y = int(map(hist[which], 0, histMax, 100, 0));
    line(i, 100, i, y);
  }
  translate(0,-620);
}

double entrop_wyj=0;

void miniaturki_show()
{
  int x=960;
  int y=0;
  for(int i=0; i<counter; i++)
  {
    image(miniaturki[i],x,y, img.width/4,img.height/4);
    if(i%2==0)
    {
      x+=img.width/4;
      
    }
    else 
    {
      y+=img.height/4;
      x=960;
    }
    
  }
  text("Ilość zdobytych próbek: "+probki+"  ile0: "+ile0+"   ile1: "+ile1,20,img.height+30);
  text("Entropia źródła: "+entrop_zrod,20,img.height+50);
  text("Entropia wyjscia: "+entrop_wyj,20,img.height+70);
}

void mouseClicked()
{
  if(mouseX>1120 && mouseX<width && mouseY>620 && mouseY<height && !generowanie)
  {
    generowanie=true;
    counter=0;
    text("klik",300,300);
    probki=0;
    histogram_wejscie=false;
    hist=new int[256];
    output = createWriter("wejscie.txt"); 
    outputbinary = createWriter("Zera_i_jedynki.txt"); 
    ile0=0;
    ile1=0;
    
  }
}
