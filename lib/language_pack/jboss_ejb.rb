require "language_pack/java6"
#require "language_pack/database_helpers"
require "fileutils"

# TODO logging
module LanguagePack
  class JBossEJB < Java6
    include LanguagePack::PackageFetcher
    #include LanguagePack::DatabaseHelpers

    JBOSS_VERSION = "jboss-5.1.0.GA".freeze
    JBOSS_DOWNLOAD = "http://114.212.85.89:80/#{JBOSS_VERSION}/"
    JBOSS_PACKAGE =  "#{JBOSS_VERSION}.tar.gz".freeze
    
    def self.use?
      Dir.glob("**/*.jar").any?
    end
    
    def name
      "JBoss ejb"
    end
   
   def compile
     Dir.chdir(build_path) do
        install_java
        install_jboss
       # remove_jboss_files
        copy_ejb_to_jboss
        move_jboss_to_root
        #install_database_drivers
        #copy_resources
        setup_profiled
      end
   end
   
   def install_jboss
     FileUtils.mkdir_p jboss_dir
     jboss_tarball = "#{jboss_dir}/#{JBOSS_PACKAGE}"
     download_jboss jboss_tarball
     puts "Unpacking Jboss to #{jboss_dir}"
     
     run_with_err_output("tar zxf #{jboss_tarball} -C #{jboss_dir}")
     
     FileUtils.rm_rf jboss_tarball
     unless File.exists?("#{jboss_dir}/#{JBOSS_VERSION}/bin/run.sh")
       puts "Unable to retrieve JBoss"
       exit 1
     end
   end
   
   def download_jboss(jboss_tarball)
     puts "Downloading Jboss: #{JBOSS_PACKAGE}"
     fetch_package JBOSS_PACKAGE
     FileUtils.mv JBOSS_PACKAGE, jboss_tarball
   end
   
   def jboss_dir
     "jboss"
   end
     
   def copy_ejb_to_jboss
     run_with_err_output("cp *.jar #{jboss_dir}/#{JBOSS_VERSION}/server/default/deploy ")
   end
     
   def move_jboss_to_root  
     run_with_err_output("mv #{jboss_dir}/* . && rm -rf #{jboss_dir}")
   end
   
   def default_process_types
     
     {
       "web" => "./bin/run.sh run"
     }
   end
      
  end
end