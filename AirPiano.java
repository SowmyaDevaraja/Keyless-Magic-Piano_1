import java.io.*;
import java.net.*;
import java.util.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.message.*;
import javax.sound.midi.MidiUnavailableException;
import org.jfugue.realtime.RealtimePlayer;
import org.jfugue.theory.Note;

public class AirPiano {
	private static final int NOTEDOWN = 1;
	private static final int NOTERIGHT = 2;
	private static final int NOTELEFT = 3;// must be the same in tinyos code
	
	public static void main(String args[]) throws MidiUnavailableException,IOException {
<<<<<<< HEAD
    	String source = null;
=======
    	String source = null;
>>>>>>> 20425215ddfb5549824c9ef103e3232e8fc06859
		int notedirection=0;
		String note = null;
		int noteid=255;
		//Note maping-----------0-----1----2-----3-----4-----5-----6----7
		String[] notedown =	{"C5" ,"D5" ,"E5","F5" ,"G5" ,"A5" ,"B5","C5"};
		String[] noteright=	{"C#5","D#5","E5","F#5","G#5","A#5","B5","C#5"};
		PacketSource reader;
		NoteBuffer notebuffer = new NoteBuffer();		
		NoteReader notereader;
		RealtimePlayer player = new RealtimePlayer();
		
		
		if (args.length == 2 && args[0].equals("-comm")) {
			source = args[1];
		}
		else if (args.length > 0) {
			System.err.println("usage: java net.tinyos.tools.AirPiano [-comm PACKETSOURCE]");
			System.err.println("       (default packet source from MOTECOM environment variable)");
			System.exit(2);
		}
		if (source == null) {	
  	  		reader = BuildSource.makePacketSource();
		}
		else {
  	  		reader = BuildSource.makePacketSource(source);
		}
		if (reader == null) {
	    	System.err.println("Invalid packet source (check your MOTECOM environment variable)");
			System.exit(2);
		}

		try {
	  		reader.open(PrintStreamMessenger.err);
  			notereader = new NoteReader(reader,notebuffer);
    		Thread notereaderthread = new Thread(notereader);	     
    		notereaderthread.start();    
    				
	  		while(true) {
	  			synchronized(notebuffer){
					try{
						notebuffer.wait();
						notedirection = notebuffer.getNote();
						noteid= notebuffer.getNoteID();	
					}catch (InterruptedException e) {
						e.printStackTrace();
					}
				}
				switch(notedirection){
					case NOTEDOWN:
						note = notedown[noteid];
						break;
					case NOTERIGHT:
						note = noteright[noteid];
						break;
					default:
						note = null;
						break;	
				}	
				if(note != null){
					player.close();				
					player.startNote(new Note(note));
					System.out.println("ID: "+ noteid+" -Note: "+note);
					note = null;
				}
	    	}
		}
		catch (IOException e) {
	    	System.err.println("Error on " + reader.getName() + ": " + e);
		}
	}
}

class NoteReader implements Runnable{
	PacketSource notereader;
	NoteBuffer notebuffer;	
	public NoteReader(PacketSource reader,NoteBuffer notebuffer){
   	this.notereader = reader;	
   	this.notebuffer = notebuffer;
   } 
	public void run(){
		byte[] packet;
      int noteid;
		int note;		
		try {			
			for (;;) {
				packet = notereader.readPacket();				
				//Dump.printPacket(System.out, packet);
				//System.out.println();
				//System.out.flush();				
				noteid= (packet[8]<<8)|(packet[9]);//16 bits node ID
				note= (packet[10]);//8 bits note direction
				synchronized(notebuffer){
					notebuffer.setNote(note);
					notebuffer.setNoteID(noteid);
					notebuffer.notifyAll();
				}			
			}	
		}
		catch(IOException e) {
			System.out.println("Serial reading error");
  		}	
	}	
}

class NoteBuffer{
<<<<<<< HEAD
	int noteid;
=======
	int noteid;
>>>>>>> 20425215ddfb5549824c9ef103e3232e8fc06859
	int note;//String note;
	
	public int getNote(){
		return this.note;	
	}
	
	public void setNote(int newnote){
		this.note = newnote;	
	}	
	public int getNoteID(){
		return this.noteid;	
	}
	
	public void setNoteID(int newnoteid){
		this.noteid = newnoteid;	
	}	
}