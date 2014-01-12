
import crayolon.portamod.*;
import java.lang.reflect.Method;

int nbTracks = 3;
Track[] tracks = new Track[nbTracks];
GlobalSettings globalSettings;
Browser browser;
Tooltip tooltip;

ArrayList<Element> elements = new ArrayList<Element>(); 

PFont font;

void setup() {
  size(800, 400);
  font = createFont("ProggyCleanTT-12.vlw", 10);
  textFont(font);
  globalSettings = new GlobalSettings(this, "global settings", 50, 20, 100, 100);
  elements.add(globalSettings);
  browser = new Browser(this, "browser", 160, 20, 300, 100);
  elements.add(browser);
  for (int i=0;i<nbTracks;i++) tracks[i] = new Track(this, "track", 50+i*240, 150, 230, 200);
  for (int i=0;i<nbTracks;i++) elements.add(tracks[i]);
  tooltip = new Tooltip(this, "tooltip", 500, 50, 200, 20);
  elements.add(tooltip);
}

void draw() {
  background(0);
  tooltip.updateTooltipFrom(elements);
  for (int i=0;i<elements.size();i++) elements.get(i).draw();
}

class Tooltip extends Element {
  String label = "";
  Tooltip(Object parent, String name, float x, float y, float w, float h) {
    super(parent, name, x, y, w, h);
  }
  void updateTooltipFrom(ArrayList<Element> elements) {
    label = "";
    for (int i=0;i<elements.size();i++) {
      String thisTooltip = elements.get(i).tooltipCheck(mouseX, mouseY);
      if (thisTooltip.length()>0) {
        label=thisTooltip;
      }
    }
  }
  void draw() {
    stroke(0x50);
    fill(0);
    rect(x, y, w, h);
    fill(0xFF, 0xFF, 0);
    if (label.length()>0) text(label, x + 5, y + 2, w, h);
  }
}

void mousePressed() {
  for (int i=0;i<elements.size();i++) elements.get(i).mousePressed(mouseX, mouseY);
}

void stop()
{
  for (int i=0;i<elements.size();i++) elements.get(i).stop();
  super.stop();
}

class Element {
  String name;
  float x, y, w, h;
  Object parent;
  ArrayList<Element> elements  = new ArrayList<Element>();
  String tooltip = "";
  Element(Object parent, String name, float x, float y, float w, float h) {
    this.parent=parent;
    this.name=name;
    this.x=x;
    this.y=y;
    this.w=w;
    this.h=h;
  }
  Element(Object parent, String name, float x, float y) {
    this(parent, name, x, y, 8, 8);
  }
  void draw() {
    pushMatrix();
    translate(x, y);
    if (w>0&&h>0) {
      noFill();
      stroke(0x50);
      rect(0, 0, w, h);
    }    
    for (int i=0;i<elements.size();i++) elements.get(i).draw();
    popMatrix();
  }
  void mousePressed(float mX, float mY) {
    float thisMX = mX-x;
    float thisMY = mY-y;
    for (int i=0;i<elements.size();i++) elements.get(i).mousePressed(thisMX, thisMY);
  }
  String tooltipCheck(float mX, float mY) {
    float thisMX = mX-x;
    float thisMY = mY-y;
    String thisTooltip = "";
    if (mouseInside(thisMX, thisMY)) {
      thisTooltip=tooltip;
    }
    for (int i=0;i<elements.size();i++) {
      String thisElementTooltip = elements.get(i).tooltipCheck(thisMX, thisMY);
      if (thisElementTooltip.length()>0) thisTooltip = thisElementTooltip;
    }
    return thisTooltip;
  }
  boolean mouseInside(float thisMX, float thisMY) {
    return thisMX>=0&&thisMY>=0&&thisMX<=w&&thisMY<=h;
  }
  void updateMethods() {
    for (int i=0;i<elements.size();i++) elements.get(i).updateMethods();
    invokeMethod();
  }
  void invokeMethod() {
  }
  void stop() {
  }
}

class GlobalSettings extends Element {
  int tempo = 100;
  GlobalSettings(Object parent, String name, float x, float y, float w, float h) {
    super(parent, name, x, y, w, h);
    try {
      elements.add(new Trigger(this, "tempo up", 10, 20, this.getClass().getMethod("tempoUp"), "increase tempo"));
      elements.add(new Trigger(this, "tempo down", 10, 30, this.getClass().getMethod("tempoDown"), "decrease tempo"));
      elements.add(new Label(this, "tempo", 25, 35, this.getClass().getMethod("getTempoFormatted")));
      elements.add(new Trigger(this, "play all", 10, 40, this.getClass().getMethod("playAll"), "play all tracks"));
    }
    catch(Exception e) {
      println(e.toString());
    }
  }
  void playAll() {
    for (int i=0;i<nbTracks;i++) {
      tracks[i].playButton.setTo(true);
    }
  }
  int getTempo() {
    return tempo;
  }
  String getTempoFormatted() {
    return tempo + "BPM";
  }
  void tempoUp() {
    tempo++;
    for (int i=0;i<nbTracks;i++) tracks[i].setTempo(tempo);
  }
  void tempoDown() {
    tempo--;
    for (int i=0;i<nbTracks;i++) tracks[i].setTempo(tempo);
  }
}

class Browser extends Element {
  int currentSongIndex = 0;
  String[] fileNames;
  Browser(Object parent, String name, float x, float y, float w, float h) {
    super(parent, name, x, y, w, h);
    try {
      elements.add(new Trigger(this, "previous song", 10, 20, this.getClass().getMethod("previousSong"), "previous song"));
      elements.add(new Trigger(this, "next song", 10, 30, this.getClass().getMethod("nextSong"), "next song"));
      elements.add(new Label(this, "label", 25, 35, this.getClass().getMethod("getCurrentSongName")));
    }
    catch(Exception e) {
      println(e.toString());
    }
    fileNames=getAllFilesFrom(sketchPath("./music"));
  }
  String getCurrentSongName() {
    String[] urlParts = split(fileNames[currentSongIndex], "\\"); 
    return urlParts[urlParts.length-1];
  }
  String getCurrentUrl() {
    return fileNames[currentSongIndex];
  }
  void previousSong() {
    currentSongIndex=(currentSongIndex-1+fileNames.length)%fileNames.length;
  }
  void nextSong() {
    currentSongIndex=(currentSongIndex+1)%fileNames.length;
  }
}

String[] getAllFilesFrom(String folderUrl) {
  File folder = new File(folderUrl);
  File[] filesPath = folder.listFiles();
  String[] result = new String[filesPath.length];
  for (int i=0;i<filesPath.length;i++) {
    result[i]=filesPath[i].toString();
  }
  return result;
}

class Track extends Element {
  private PortaMod mymod;
  Element channels;
  Toggle playButton;
  boolean validTrack = false;
  String songName = "";
  int globalTranspose;
  Track(Object parent, String name, float x, float y, float w, float h) {
    super(parent, name, x, y, w, h);
    mymod = new PortaMod((PApplet)parent);
    try {
      elements.add(new Trigger(this, "load", 10, 10, this.getClass().getMethod("load"), "load"));
      elements.add(new Label(this, "song name", 25, 17, this.getClass().getMethod("getSongName")));
      elements.add(new Label(this, "initial tempo", 10, 32, this.getClass().getMethod("getFormattedInitialTempo")));
      elements.add(new Trigger(this, "transpose up", 10, 40, this.getClass().getMethod("transposeUp"), "transpose up"));
      elements.add(new Trigger(this, "transpose down", 10, 50, this.getClass().getMethod("transposeDown"), "transpose down"));
      elements.add(new Label(this, "transpose", 25, 52, this.getClass().getMethod("getTranspose")));
      playButton = new Toggle(this, "play", 30, 60, this.getClass().getMethod("play", boolean.class), false, "play", "pause");
      elements.add(playButton);
      elements.add(new Trigger(this, "reset playhead", 20, 60, this.getClass().getMethod("resetPlayhead"), "rewind"));
      // elements.add(new TimelineManager(this, "timeline manager", 20, 70, 150, 20));
      channels = new Channels(this, "channels", 10, 100);
      elements.add(channels);
    }
    catch(Exception e) {
      println(e.toString());
    }
  }

  String getSongName() {
    return songName;
  }

  String getFormattedInitialTempo() {
    return mymod.initialtempo + " BPM";
  }

  int getInitialTempo() {
    return mymod.initialtempo;
  }

  void load() {
    loadTrack(browser.getCurrentUrl());
    songName = mymod.getTitle();
    if (songName.length()==0) songName=browser.getCurrentSongName();
  }

  int getTranspose() {
    return globalTranspose;
  }

  void resetPlayhead() {
    mymod.setSeek(0);
    mymod.setOverridetempo(true);
    mymod.setTempo(globalSettings.getTempo());
  }

  float getPlayheadPosition() {
    // TODO find a way to make each Portamod instance specific to each track
    if (mymod.numpatterns==0) return -1;
    else return (float)(mymod.sequencecounter) / (float)(mymod.numpatterns);
  }

  void play(boolean state) {
    if (state) mymod.play();
    else mymod.pause();
  }

  void transposeUp() {
    globalTranspose=constrain(globalTranspose+1, -12, 12);
    channels.updateMethods();
  }
  void transposeDown() {
    globalTranspose=constrain(globalTranspose-1, -12, 12);
    channels.updateMethods();
  }
  void channelMute(int id, boolean state) {
    mymod.setChanmute(id, !state);
  }
  void loadTrack(String url) {
    mymod.doModLoad(url, false, 64);
    playButton.setTo(false);
    if (mymod.numchannels>0) {
      mymod.interpolation = 0;
      mymod.setOverridetempo(true);      
      mymod.setTempo(globalSettings.getTempo());
      mymod.setStereosep(5);
      ((Channels)channels).setQuantity(mymod.numchannels);
      validTrack=true;
    }
    else {
      print("unable to load "+url);
      validTrack=false;
    }
    channels.updateMethods();
  }
  void setTempo(int t) {
    mymod.setTempo(t);
    channels.updateMethods();
  }
  void transposeLink(int id, boolean state) {
    if (state) {
      float ratio =((float)globalSettings.tempo)/((float)mymod.initialtempo);
      mymod.setTranspose(id, (int)round(12*log(ratio)/log(2.0)));
    }
    else {
      mymod.setTranspose(id, globalTranspose);
    }
  }
  void stop() {
    mymod.stop();
  }
  public float getChanVol(int c) {
    try {
      return mymod.getChanvol(c);
    }
    catch(Exception e) {
      return 0;
    }
  }
}

class Trigger extends Element {
  Method method;
  Trigger(Object parent, String name, float x, float y, Method method) {
    super(parent, name, x, y);
    this.method=method;
  }
  Trigger(Object parent, String name, float x, float y, Method method, String tooltip) {
    this(parent, name, x, y, method);
    this.tooltip=tooltip;
  }
  void draw() {
    stroke(0xFF);
    fill(0);
    rect(x, y, w, h);
  }
  void mousePressed(float mX, float mY) {
    if (method!=null) {
      float thisMX = mX-x;
      float thisMY = mY-y;
      if (mouseInside(thisMX, thisMY)) {
        invokeMethod();
      }
    }
  }
  void invokeMethod() {
    try {
      method.invoke(parent);
    }
    catch(Exception e) {
      println(e.toString());
    }
  }
}

class TimelineManager extends Element {
  Timeline timeline;
  TimelineManager(Object parent, String name, float x, float y, float w, float h) {
    super(parent, name, x, y, w, h);
    timeline = new Timeline(this, "timeline", 5, 5, 100, 10);
    elements.add(timeline);
  }
  void draw() {
    timeline.setCursor(((Track)parent).getPlayheadPosition());
    super.draw();
  }
}

class Timeline extends Element {
  float cursor=0;
  Timeline(Object parent, String name, float x, float y, float w, float h) {
    super(parent, name, x, y, w, h);
  }
  void draw() {
    stroke(0xFF);
    fill(0);
    rect(x, y, w, h);
    stroke(0, 0xFF, 0);
    if (cursor>=0 && cursor<=1) line(x+cursor*w, y, x+cursor*w, y+h);
  }
  void setCursor(float cursor) {
    this.cursor=cursor;
  }
}

class Label extends Element {
  Method method;
  String text="";
  Label(Object parent, String name, float x, float y, Method method) {
    super(parent, name, x, y);
    this.method=method;
  }
  void draw() {
    stroke(0xFF);
    fill(0xFF);
    invokeMethod();
    text(text, x, y);
  }
  void invokeMethod() {
    if (method!=null) {
      try {
        text = method.invoke(parent).toString();
      }
      catch(Exception e) {
        println(e.toString());
      }
    }
  }
}

class Toggle extends Element {
  Method method;
  boolean state;
  String[] tooltips = new String[2];
  Toggle(Object parent, String name, float x, float y, Method method, boolean state) {
    super(parent, name, x, y);
    this.method=method;
    this.state=state;
  }
  Toggle(Object parent, String name, float x, float y, Method method, boolean state, String tooltipOff, String tooltipOn) {
    this(parent, name, x, y, method, state);
    this.tooltips[0]=tooltipOff;
    this.tooltips[1]=tooltipOn;
    this.tooltip = state ? tooltips[1] : tooltips[0];
  }
  void draw() {
    stroke(0xFF);
    if (state) fill(0x00, 0x00, 0xFF);
    else fill(0);
    rect(x, y, w, h);
  }
  void mousePressed(float mX, float mY) {
    if (method!=null) {
      float thisMX = mX-x;
      float thisMY = mY-y;
      if (mouseInside(thisMX, thisMY)) {
        state^=true;
        this.tooltip = state ? tooltips[1] : tooltips[0]; 
        invokeMethod();
      }
    }
  }
  void invokeMethod() {
    try {
      method.invoke(parent, state);
    }
    catch(Exception e) {
      println(e.toString());
    }
  }
  void setTo(boolean state) {
    this.state = state;
    this.tooltip = state ? tooltips[1] : tooltips[0];   
    invokeMethod();
  }
}

class VuFade extends Element {
  float light;
  VuFade(Object parent, String name, float x, float y, float light) {
    super(parent, name, x, y);
    this.light=0;
  }
  void draw() {
    stroke(0xFF);
    fill(0, light, 0);
    rect(x, y, w, h);
  }
  void setLight(float l) {
    light = l;
  }
}

class Channels extends Element {
  int quantity;
  Channels(Object parent, String name, float x, float y) {
    super(parent, name, x, y);
    this.h=50;
  }
  void setQuantity(int quantity) {
    this.quantity=quantity;
    int lineBreak = 16;
    this.h=5+40*ceil((float)quantity/(float)lineBreak);
    this.w=min(quantity, lineBreak)*10+10;
    elements = new ArrayList<Element>();
    for (int i=0;i<quantity;i++) {
      float thisX = 5+(i%lineBreak)*10;
      float thisY = 5+floor((float)i/lineBreak)*40;
      elements.add(new Channel(this, "channel", thisX, thisY, i));
    }
  }
}

class Channel extends Element {
  int id;
  VuFade vuFade;
  Channel(Object parent, String name, float x, float y, int id) {
    super(parent, name, x, y);
    this.id=id;
    this.w=0;
    this.h=0;
    try {
      elements.add(new Toggle(this, "channel mute", 0, 0, this.getClass().getMethod("channelMute", boolean.class), true, "unmute channel", "mute channel"));
      vuFade = new VuFade(this, "vu meter", 0, 10, 0);
      elements.add(new Toggle(this, "transpose link", 0, 20, this.getClass().getMethod("transposeLink", boolean.class), false, "link pitch and speed", "unlink pitch and speed"));
      elements.add(vuFade);
    }
    catch(Exception e) {
      println(e.toString());
    }
  }
  void channelMute(boolean state) {
    ((Track)((Channels)parent).parent).channelMute(id, state);
  }
  void transposeLink(boolean state) {
    ((Track)((Channels)parent).parent).transposeLink(id, state);
  }  
  void draw() {
    vuFade.setLight(((Track)((Channels)parent).parent).getChanVol(id)*4);
    super.draw();
  }
}

