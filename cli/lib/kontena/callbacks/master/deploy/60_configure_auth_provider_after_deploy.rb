module Kontena
  module Callbacks
    class ConfigureAuthProviderAfterDeploy < Kontena::Callback

      include Kontena::Cli::Common

      matches_commands 'master create'

      def init_cloud_args
        args = []
        args << '--force' 
        args << "--cloud-master-id #{command.cloud_master_id}" if command.cloud_master_id
        args << "--provider #{command.result[:provider]}" if command.result[:provider]
        args << "--version #{command.result[:version]}" if command.result[:version]
        args.join(' ')
      end

      def configure_auth_provider
        Kontena.run("master init-cloud #{init_cloud_args}")
      end

      def after
        return unless command.exit_code == 0
        return unless command.result.kind_of?(Hash)
        return unless command.result.has_key?(:name)
        return unless config.current_master
        return unless config.current_master.name == command.result[:name]
        if command.respond_to?(:skip_auth_provider?) && command.skip_auth_provider?
          return
        end

        configure_auth_provider
      end
    end
  end
end

