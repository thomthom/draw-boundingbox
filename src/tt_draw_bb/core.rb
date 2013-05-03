#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'
begin
  require 'TT_Lib2/core.rb'
rescue LoadError => e
  module TT
    if @lib2_update.nil?
      url = 'http://www.thomthom.net/software/sketchup/tt_lib2/errors/not-installed'
      options = {
        :dialog_title => 'TT_Lib² Not Installed',
        :scrollable => false, :resizable => false, :left => 200, :top => 200
      }
      w = UI::WebDialog.new( options )
      w.set_size( 500, 300 )
      w.set_url( "#{url}?plugin=#{File.basename( __FILE__ )}" )
      w.show
      @lib2_update = w
    end
  end
end


#-------------------------------------------------------------------------------

if defined?( TT::Lib ) && TT::Lib.compatible?( '2.7.0', 'Draw BoundingBox' )

module TT::Plugins::DrawBoundingBox
  
  ### MENU & TOOLBARS ### ------------------------------------------------------
  
  unless file_loaded?( __FILE__ )
    # Menus
    m = TT.menu( 'Draw' )
    m.add_item( 'Boundingbox' ) { self.draw_bb }
  end 
  
  
  ### MAIN SCRIPT ### ----------------------------------------------------------

  def self.draw_bb
    model = Sketchup.active_model
    ents = model.active_entities
    entity = model.selection.first
    # Verify selection
    if model.selection.empty?
      UI.messagebox('No Groups or Components selected.')
      return
    end
    # Defaults
    draw = Sketchup.read_default(PLUGIN_ID, 'Draw', 'Faces')
    # Prompt for creation method
    prompts = ['Draw: ']
    defaults = [draw]
    lists = ['Faces|Construction Geometry']
    input = UI.inputbox(prompts, defaults, lists, 'Draw Boundingboxes')
    return unless input
    draw_faces = input[0] == 'Faces'
    # Write ddefaults
    Sketchup.write_default(PLUGIN_ID, 'Draw', input[0])
    # Draw the boxes
    TT::Model.start_operation('Draw Boundingbox')
    model.selection.each { |entity|
      next unless TT::Instance.is?(entity)
      definition = TT::Instance.definition(entity)
      bb = definition.bounds
      pts = self.bound_points(bb).map { |pt| pt.transform( entity.transformation ) }
      if pts.length == 8
        if draw_faces
          faces = [
            [ pts[0], pts[2], pts[3], pts[1] ],
            [ pts[0], pts[4], pts[5], pts[1] ],
            [ pts[0], pts[4], pts[6], pts[2] ],
            [ pts[2], pts[6], pts[7], pts[3] ],
            [ pts[3], pts[7], pts[5], pts[1] ],
            [ pts[4], pts[6], pts[7], pts[5] ]
            ]
        else
          faces = [
            [ pts[0], pts[1] ],
            [ pts[1], pts[3] ],
            [ pts[3], pts[2] ],
            [ pts[2], pts[0] ],
            
            [ pts[4], pts[5] ],
            [ pts[5], pts[7] ],
            [ pts[7], pts[6] ],
            [ pts[6], pts[4] ],
            
            [ pts[0], pts[4] ],
            [ pts[1], pts[5] ],
            [ pts[2], pts[6] ],
            [ pts[3], pts[7] ]
            ]
        end
      else
        if draw_faces
          faces = [ pts ]
        else
          faces = [
            [ pts[0], pts[1] ],
            [ pts[1], pts[2] ],
            [ pts[2], pts[3] ],
            [ pts[3], pts[0] ]
          ]
        end
      end
      faces.each { |face|
        if draw_faces
          ents.add_face( face )
        else
          face.each { |pt| ents.add_cpoint(pt) }
          ents.add_cline( face[0], face[1] )
        end
      }
    } # each
    model.commit_operation
  end

  
  ### HELPER METHODS ### ---------------------------------------------------
  
  def self.bound_is_2d?(bound)
    bound.width == 0 || bound.height == 0 || bound.depth == 0
  end
  
  def self.bound_points(bound)
    if bound.width == 0
      [0,2,6,4].map { |i| bound.corner(i) }
    elsif bound.height == 0
      [0,1,5,4].map { |i| bound.corner(i) }
    elsif bound.depth == 0
      [0,1,3,2].map { |i| bound.corner(i) }
    else
      (0..7).map { |i| bound.corner(i) }
    end
  end
  
### DEBUG ### ----------------------------------------------------------------
  
  # @note Debug method to reload the plugin.
  #
  # @example
  #   TT::Plugins::Template.reload
  #
  # @param [Boolean] tt_lib Reloads TT_Lib2 if +true+.
  #
  # @return [Integer] Number of files reloaded.
  # @since 1.0.0
  def self.reload( tt_lib = false )
    original_verbose = $VERBOSE
    $VERBOSE = nil
    TT::Lib.reload if tt_lib
    # Core file (this)
    load __FILE__
    # Supporting files
    if defined?( PATH ) && File.exist?( PATH )
      x = Dir.glob( File.join(PATH, '*.{rb,rbs}') ).each { |file|
        load file
      }
      x.length + 1
    else
      1
    end
  ensure
    $VERBOSE = original_verbose
  end

end # module

end # if TT_Lib

#-------------------------------------------------------------------------------

file_loaded( __FILE__ )

#-------------------------------------------------------------------------------