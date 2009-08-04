module Jekyll

  module Engines
    def self.setup(config)
      # Set the Markdown interpreter (and Maruku self.config, if necessary)
      @@config = config
      case config['markdown']
      when 'rdiscount'
        begin
          require 'rdiscount'
        rescue LoadError
          puts 'You must have the rdiscount gem installed first'
        end
      when 'maruku'
        begin
          require 'maruku'

          if config['maruku']['use_divs']
            require 'maruku/ext/div'
            puts 'Maruku: Using extended syntax for div elements.'
          end

          if config['maruku']['use_tex']
            require 'maruku/ext/math'
            puts "Maruku: Using LaTeX extension. Images in `#{config['maruku']['png_dir']}`."

            # Switch off MathML output
            MaRuKu::Globals[:html_math_output_mathml] = false
            MaRuKu::Globals[:html_math_engine] = 'none'

            # Turn on math to PNG support with blahtex
            # Resulting PNGs stored in `images/latex`
            MaRuKu::Globals[:html_math_output_png] = true
            MaRuKu::Globals[:html_png_engine] =  config['maruku']['png_engine']
            MaRuKu::Globals[:html_png_dir] = config['maruku']['png_dir']
            MaRuKu::Globals[:html_png_url] = config['maruku']['png_url']
          end
        rescue LoadError
          puts 'The maruku gem is required for markdown support!'
        end
      end
    end

    def self.textile(content)
      RedCloth.new(content).to_html
    end

    def self.markdown(content)
      @@config['markdown'] == "maruku" ? self.maruku(content) : self.rdiscount(content)
    end

    def self.maruku(content)
      Maruku.new(content).to_html
    end

    def self.rdiscount(content)
      RDiscount.new(content).to_html
    end

    def self.haml(content)
      require "haml"
      Haml::Engine.new(content, :suppress_eval => true).render
    end
  end

end
