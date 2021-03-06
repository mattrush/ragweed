require 'ffi'

module Ragweed

  # :stopdoc:
  VERSION = File.read(File.join(File.dirname(__FILE__),"..","VERSION")).strip
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  # Returns the library path for the module. If any arguments are given,
  # they will be joined to the end of the libray path using
  # <tt>File.join</tt>.
  #
  def self.libpath( *args )
    args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
  end

  # Returns the lpath for the module. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, args.flatten)
  end

  # Utility method used to require all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= ::File.basename(fname, '.*')
    search_me = ::File.expand_path(
        ::File.join(::File.dirname(fname), dir, '**', '*.rb'))
    # Don't want to load wrapper or debugger here.
    Dir.glob(search_me).sort.reject{|rb| rb =~ /(wrap|debugger|rasm[^\.])/}.each {|rb| require rb}
    # require File.dirname(File.basename(__FILE__)) + "/#{x}"d
  end

  def self.require_os_libs_relative_to( fname, dir= nil )
    dir ||= ::File.basename(fname, '.*')
    pkgs = ""
    dbg = ""

    case
    when ::FFI::Platform.windows?
      pkgs = '32'
    when ::FFI::Platform.mac?
      pkgs = 'osx'
    # coming soon
    # when ::FFI::Platform.bsd?
    #   pkgs = "bsd"
    when ::FFI::Platform.unix? && ! ::FFI::Platform.bsd?
      # FFI doesn't specifically detect linux so... we punt
      pkgs = 'tux'
    else
      warn "Platform not supported no wrapper libraries loaded."
    end
    
    if not pkgs.empty?
      search_me = File.expand_path(File.join(File.dirname(fname), dir, "*#{pkgs}.rb"))
      Dir.glob(search_me).sort.reverse.each {|rb| require rb}
    end
  end
end  # module Ragweed

## FFI Struct Accessor Methods
module Ragweed::FFIStructInclude
  if RUBY_VERSION < "1.9"
    def methods regular=true
      (super + self.members.map{|x| [x.to_s, x.to_s+"="]}).flatten
    end
  else
    def methods regular=true
      (super + self.members.map{|x| [x, (x.to_s+"=").intern]}).flatten
    end
  end

  def method_missing meth, *args
    super unless self.respond_to? meth
    if meth.to_s =~ /=$/
      self.__send__(:[]=, meth.to_s.gsub(/=$/,'').intern, *args)
    else
      self.__send__(:[], meth, *args)
    end
  end

  def respond_to? meth, include_priv=false
    # mth = meth.to_s.gsub(/=$/,'')
    !((self.methods & [meth, meth.to_s]).empty?) || super
  end
end

# pkgs = %w[arena sbuf ptr process event rasm blocks detour trampoline device debugger hooks]
# pkgs << 'wrap32' if RUBY_PLATFORM =~ /win(dows|32)/i
# pkgs << 'wraposx' if RUBY_PLATFORM =~ /darwin/i
# pkgs << 'wraptux' if RUBY_PLATFORM =~ /linux/i
# pkgs.each do |x|
#   require File.dirname(__FILE__) + "/#{x}"
# end


Ragweed.require_os_libs_relative_to(__FILE__)
Ragweed.require_all_libs_relative_to(__FILE__)
# EOF
