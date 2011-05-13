module Sinatra
  module Ska
    module FacebookHelpers
      def authorize_url(scope='')
        scope = scope.is_a?(Array) ? scope.join(',') : scope
        auth_url = "#{::Ska::FB_OPEN_GRAPH_URL}/oauth/authorize?"+
                   "client_id=#{@@config.api_key}&"+
                   "redirect_uri=#{CGI.escape FacebookHelpers.url_for(request.path[1..request.path.length])}"
        auth_url << "&scope=#{scope}" if scope
      end
      
      def self.registered(app); app.helpers Ska::FacebookHelpers end
      def redirect(path); halt %{<script type="text/javascript">top.location.href = "#{path}";</script>} end

      def url_for(path, opts={})
        path.sub!(/^\//, '')  
        if opts[:skip_facebook]
          "#{Sinatra::Ska.config.callback_url}/#{path}"
        else
          "http://apps.facebook.com/#{Sinatra::Ska.config.canvas_page_name}/#{path}"
        end
      end
      module_function :url_for

      def url_for_page_tab; Sinatra::Ska.config.page_tab_url end
      def url_for_img(filename); url_for "img/#{filename}", :skip_facebook => true end
    end
  end

  register Ska::FacebookHelpers
end