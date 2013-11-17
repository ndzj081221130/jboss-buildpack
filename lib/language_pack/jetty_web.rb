require "language_pack/java"
#require "language_pack/database_helpers"
require "fileutils"

# TODO logging
module LanguagePack
  class JettyWeb < Java
    include LanguagePack::PackageFetcher
    #include LanguagePack::DatabaseHelpers

    JETTY_VERSION = "9.0.3.v20130506".freeze
    JETTY_DOWNLOAD = "http://repo2.maven.org/maven2/org/eclipse/jetty/jetty-distribution/#{JETTY_VERSION}/"
    JETTY_PACKAGE =  "jetty-distribution-#{JETTY_VERSION}.tar.gz".freeze
    WEBAPP_DIR = "webapps/ROOT/".freeze

    def self.use?
      File.exists?("WEB-INF/web.xml") || File.exists?("webapps/ROOT/WEB-INF/web.xml")
    end

    def name
      "Java Web"
    end

    def compile
      Dir.chdir(build_path) do
        install_java
        install_jetty
        remove_jetty_files
        #tweak_jetty_port
        copy_webapp_to_jetty
        move_jetty_to_root
        #install_database_drivers
        copy_resources
        setup_profiled
      end
    end

    def install_jetty
      FileUtils.mkdir_p jetty_dir
      jetty_tarball="#{jetty_dir}/#{JETTY_PACKAGE}"

      download_jetty jetty_tarball

      puts "Unpacking Jetty to #{jetty_dir}"
      run_with_err_output("tar xzf #{jetty_tarball} -C #{jetty_dir} && mv #{jetty_dir}/jetty-distribution*/* #{jetty_dir} && " +
              "rm -rf #{jetty_dir}/jetty-distribution*")
      FileUtils.rm_rf jetty_tarball
      unless File.exists?("#{jetty_dir}/bin/jetty.sh")
        puts "Unable to retrieve Jetty"
        exit 1
      end
    end

    def download_jetty(jetty_tarball)
      puts "Downloading Jetty: #{JETTY_PACKAGE}"
      fetch_package JETTY_PACKAGE, JETTY_DOWNLOAD
      FileUtils.mv JETTY_PACKAGE, jetty_tarball
    end

    def remove_jetty_files
      %w[webapps/. start.d/900-demo.ini webapps.demo].each do |file|
        #puts "Removing: #{jetty_dir}/#{file}"
        FileUtils.rm_rf("#{jetty_dir}/#{file}")
      end
    end

    def jetty_dir
      ".jetty"
    end

    def copy_webapp_to_jetty
      run_with_err_output("mkdir -p #{jetty_dir}/webapps/ROOT && mv * #{jetty_dir}/webapps/ROOT")
    end

    def move_jetty_to_root
      run_with_err_output("mv #{jetty_dir}/* . && rm -rf #{jetty_dir}")
    end

    def copy_resources
      # copy jetty configuration updates into place
      run_with_err_output("cp -r #{File.expand_path('../../../resources/jetty', __FILE__)}/* #{build_path}")
    end

    def java_opts
      #opts = super.merge({ "-Djetty.port=" => "$PORT" })
      opts = super.merge({ "-Djetty.home=" => ".", "-Djetty.port=" => "$PORT" })
      opts.delete("-Djava.io.tmpdir=")
      opts.delete("-XX:OnOutOfMemoryError=")
      opts
    end

    #def tweak_jetty_port
    #  port=ENV['PORT']
    #  run_with_err_output("perl -pi -e 's/jetty.port=8080/jetty.port=$port/' #{jetty_dir}/start.ini")
    #end

    def default_process_types
      {
        "web" => "./bin/jetty.sh run"
      }
    end

    def webapp_path
      File.join(build_path,"webapps","ROOT")
    end
  end
end
