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

        //��ȡ��ǰclass·���� ��Ҫ���ڶ�λffmpeg.exe�ļ�
        //���ffmpeg.exeû���ڵ�ǰĿ¼�¾Ͳ�����������
        String modulePath = Thread.currentThread().getContextClassLoader().getResource("./").getPath();

        //ִ��ffmpeg.exe·���� -i ����Ϊ�����ļ�
        //�����ļ���ffmpeg·������Ϊ����·��
        String commandLineArgc = new String();;
        commandLineArgc += " -y -f  image2 ";
        commandLineArgc += " -vframes 1 ";

        //-i                    ����Ϊ�����ļ�
        //-sameq                ӰƬ��������һ�£��ᵼ��Ŀ���ļ�����)
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

            //��������ʱ��ִ������
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
            p.waitFor();
        } 
        catch (Exception e) {
            e.printStackTrace();
        }  
    }
}