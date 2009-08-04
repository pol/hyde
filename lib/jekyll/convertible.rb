# Convertible provides methods for converting a pagelike item
# from a certain type of markup into actual content
#
# Requires
#   self.site -> Jekyll::Site
module Jekyll
  module Convertible
    # Return the contents as a string
    def to_s
      self.content || ''
    end

    # Read the YAML frontmatter
    #   +base+ is the String path to the dir containing the file
    #   +name+ is the String filename of the file
    #
    # Returns nothing
    def read_yaml(base, name)
      self.content = File.read(File.join(base, name))
      
      if self.content =~ /^(---\s*\n.*?\n?)(---.*?\n)/m
        self.content = self.content[($1.size + $2.size)..-1]
      
        self.data = YAML.load($1)
      end
      
      self.data ||= {}
    end

    # Transform the contents based on content type.
    #
    # Returns nothing
    def transform
      return if %w(html xml atom rss).include?(self.content_type) # no transformation needed
      self.content = Engines.method(self.content_type.to_sym).call(self.content)
      self.ext = ".html"
    end

    # Determine which formatting engine to use based on this convertible's
    # extension
    #
    # Returns the content type as a string, usually the same as the extension
    def content_type
      case self.ext[1..-1]
      when /markdown/i, /mkdn/i, /md/i # aliases for the Markdown format
        return 'markdown'
      end
      ext[1..-1]
    end

    # Add any necessary layouts to this convertible document
    #   +layouts+ is a Hash of {"name" => "layout"}
    #   +site_payload+ is the site payload hash
    #
    # Returns nothing
    def do_layout(payload, layouts)
      info = { :filters => [Jekyll::Filters], :registers => { :site => self.site } }

      # render and transform content (this becomes the final content of the object)
      payload["content_type"] = self.content_type
      self.content = Liquid::Template.parse(self.content).render(payload, info)
      self.transform

      # output keeps track of what will finally be written
      self.output = self.content

      # recursively render layouts
      layout = layouts[self.data["layout"]]
      while layout
        payload = payload.deep_merge({"content" => self.output, "page" => layout.data})
        layout.transform
        self.output = Liquid::Template.parse(layout.content).render(payload, info)

        layout = layouts[layout.data["layout"]]
      end
    end
  end
end
