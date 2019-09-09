import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.*;

public class ffmpeg 
{
    public static void main(String[] args) {

      if (args.length == 0)
      {
          System.out.println("plase set input file path");
          return;
      }

      //��ȡ��ǰclass·���� ��Ҫ���ڶ�λffmpeg.exe�ļ�
      //mencoder.exeû���ڵ�ǰĿ¼�¾Ͳ�����������
      String modulePath = Thread.currentThread().getContextClassLoader().getResource("./").getPath();
      modulePath = modulePath.substring(1);

      List<String> fileList = new ArrayList<String>();
      List<String> jiamiFileList = new ArrayList<String>();

      for (String inputFile : args) {

        //����ļ�Ŀ¼�� ��Ҫ���۾ͱ���ʹ��flv��չ���� ffmpeg��ʹ����չ������ִ�ļ�����
        String outputFileName = inputFile + ".flv";
        String prefix = inputFile.substring(inputFile.lastIndexOf(".")+1);

        jiamiFileList.add(outputFileName);

         if (prefix.equals("rmvb") || prefix.equals("mpg") ) {   

            String commandLineArgc = "-oac mp3lame ";
            commandLineArgc += "-lameopts abr:br=56 ";
            commandLineArgc += "-srate 22050 ";
            commandLineArgc += "-af channels=2 ";
            commandLineArgc += "-ovc lavc ";
            commandLineArgc += "-vf harddup,hqdn3d ";
            commandLineArgc += "-lavcopts vcodec=flv:vbitrate=2000:mbd=2:trell:v4mv:last_pred=2:dia=-1:vb_strategy=1:cmp=3:subcmp=3:precmp=0:vqcomp=0.6:turbo:keyint=45 ";  
            commandLineArgc += "-ofps 15 ";
            commandLineArgc += "-of lavf ";

            String commandLine = String.format(
              "cmd /c \"%s/WisMencoder/mencoder.exe %s -o %s %s \"", 
              modulePath, inputFile, outputFileName, commandLineArgc);
            fileList.add(commandLine);    
           }
          else if (prefix.equals("avi")) {

            String commandLineArgc = "-of lavf ";
            commandLineArgc += "-oac mp3lame ";
            commandLineArgc += "-lameopts abr:br=56 ";
            commandLineArgc += "-ovc lavc ";
            commandLineArgc += "-lavcopts vcodec=flv:vbitrate=5000:mbd=2:mv0:trell:v4mv:cbp:last_pred=3 ";
            commandLineArgc += "-sws 1 ";
            commandLineArgc += "-ofps 30 ";        
            commandLineArgc += "-srate 22050 ";   
            String commandLine = String.format(
              "cmd /c \"%s/WisMencoder/mencoder.exe %s -o %s %s \"", 
              modulePath, inputFile, outputFileName, commandLineArgc);
            fileList.add(commandLine); 
          } else if (prefix.equals("mkv")) {
            String commandLineArgc = "-qscale 0 "; 
            commandLineArgc += "-ar 22050 ";
            commandLineArgc += "-y ";
            String commandLine = String.format(
                  "cmd /c \"%s/ffmpeg.exe -i %s %s %s\"", 
                  modulePath, inputFile, commandLineArgc, outputFileName);
            fileList.add(commandLine); 

          } else  {

            String commandLineArgc = "-qscale 0.01 "; 
            commandLineArgc += "-acodec libmp3lame ";
            commandLineArgc += "-r 29.97 ";
            commandLineArgc += "-y ";
            String commandLine = String.format(
                  "cmd /c \"%s/ffmpeg.exe -i %s %s %s\"", 
                  modulePath, inputFile, commandLineArgc, outputFileName);
            fileList.add(commandLine);
          }
      }
            
      processFileList(fileList);
    }

    public static void processFileList(List<String> fileList) {
        
      for (String commandLine : fileList) {

          try 
          {
              //��������ʱ��ִ������
            System.out.println("start process " +  commandLine);
            Process p = Runtime.getRuntime().exec(commandLine);

            //��ȡ���̵ı�׼������  
            final InputStream is1 = p.getInputStream();   
            //��ȡ���ǵĴ�����  
            final InputStream is2 = p.getErrorStream();  
            //���������̣߳�һ���̸߳������׼���������һ���������׼������  
            new Thread() 
            {  
                public void run() 
                {  
                   BufferedReader br1 = new BufferedReader(new InputStreamReader(is1));  
                    try 
                    {  
                        String line1 = null;  
                        while ((line1 = br1.readLine()) != null)
                        {  
                              if (line1 != null){
                                System.out.println(line1);
                              }  
                        }  
                    } 
                    catch (Exception e) 
                    {  
                         e.printStackTrace();  
                    }  
                    finally
                    {  
                        try 
                        {  
                          is1.close();  
                        } 
                        catch (Exception e) 
                        {  
                            e.printStackTrace();  
                        }  
                      }  
                    }  
                 }.start();  
                                            
               new Thread() 
               {   
                  public void  run() 
                  {   
                   BufferedReader br2 = new  BufferedReader(new  InputStreamReader(is2));   
                      try 
                      {   
                         String line2 = null ;   
                         while ((line2 = br2.readLine()) !=  null ) 
                         {   
                              if (line2 != null){
                                System.out.println(line2);
                              }  
                         }   
                       } 
                       catch (Exception e) 
                       {   
                             e.printStackTrace();  
                       }   
                      finally
                      {  
                         try 
                         {  
                             is2.close();  
                         } 
                         catch (Exception e) 
                         {  
                             e.printStackTrace();  
                         }  
                       }  
                    }   
                  }.start();  
            long startTime =  System.currentTimeMillis();
            p.waitFor();
            long spaceTime = System.currentTimeMillis() - startTime;
            System.out.println(spaceTime / 1000);
          } 
          catch (Exception e) {
              e.printStackTrace();
          }  
      }
    }
}