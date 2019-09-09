import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;

public class image 
{
    public static void main(String[] args) {

        if (args.length != 3)
        {
            System.out.println("plase set input file path");
            return;
        }

        String inputFile = args[0];
        String time = args[1];
        String imageFile = args[2];

        //获取当前class路径， 主要用于定位ffmpeg.exe文件
        //如果ffmpeg.exe没有在当前目录下就不用这样做了
        String modulePath = Thread.currentThread().getContextClassLoader().getResource("./").getPath();

        //执行ffmpeg.exe路径， -i 参数为输入文件
        //输入文件和ffmpeg路径必须为绝对路径
        String commandLineArgc = new String();;
        commandLineArgc += " -y -f  image2 ";
        commandLineArgc += " -vframes 1 ";

        //-i                    参数为输入文件
        //-sameq                影片质量保持一致（会导致目标文件增大)
        try 
        {
            String commandLine = String.format(
                "%s/ffmpeg.exe -i \"%s\" %s -ss %s \"%s\"", 
                modulePath,
                inputFile,
                commandLineArgc, 
                time,
                imageFile);
            System.out.println(commandLine);

            //调用运行时库执行命令
            Process p = Runtime.getRuntime().exec(commandLine);
             //获取进程的标准输入流  
            final InputStream is1 = p.getInputStream();   
            //获取进城的错误流  
            final InputStream is2 = p.getErrorStream();  
            //启动两个线程，一个线程负责读标准输出流，另一个负责读标准错误流  
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
            p.waitFor();
        } 
        catch (Exception e) {
            e.printStackTrace();
        }  
    }
}