require "securerandom"
require "yaml"

class Secrets

  KMS_KEYRING = "keyring"

  SECRETS_DIR = "secrets"
  VALUES_DIR = "values"

  SECRETS_FILE = "secrets.yaml"

  # This method is looking for SECRETS_FILE files in module directories (modules/*), which should have the following structure:
  #
  # secrets:
  #  - secret_name
  #  - another_secret
  #  - and_one_more_secret
  # encryption_key: default
  #
  # Attribute "encryption_key" is optional – if not present, module name will be used as Key name
  # After collecting, it returns the Hash with collected secrets, where the keys are KMS Encryption Keys and the values are
  # lists of individual credentials (e.g. couchdb_password) managed with that KMS Encryption Key
  def self.collect_secrets()
    ENV['TF_VAR_keyring_name'] = Secrets::KMS_KEYRING

    encryption_keys = []
    collected_secrets = {}

    Dir["../../modules/**/#{Secrets::SECRETS_FILE}"].each do |module_secrets_file|
      module_default_key = File.basename(File.dirname(module_secrets_file))
      module_secrets = YAML.load(File.read(module_secrets_file))

      encryption_key = module_secrets['encryption_key'] ? module_secrets['encryption_key'] : module_default_key
      encryption_keys << %Q|"#{encryption_key}"|

      if collected_secrets[encryption_key]
        collected_secrets[encryption_key].concat(module_secrets['secrets'])
      else
        collected_secrets[encryption_key] = module_secrets['secrets']
      end
      module_secrets['secrets'].each do |secret_name|
        ENV["TF_VAR_#{secret_name}"] = ""
      end

      collected_secrets[encryption_key].uniq!
    end

    encryption_keys.uniq!
    ENV["TF_VAR_encryption_keys"] = %Q|[ #{encryption_keys.join(", ")} ]|

    return collected_secrets
  end


  # This method is setting secret ENV variables collected from modules
  # It uses exekube secret-mgmt module scripts: secrets-fetch and secrets-push
  #
  # When encrypted secret file for current env is not present it GS bucket,
  # for every secret it first looks for ENV[secret_name.upcase] and, if it is not set,
  # populates secret with random nonse, and then uploads to corresponding GS bucket.
  #
  # When encrypted secret file is present, it always uses its decrypted data as a source for secrets.
  # Use `rake destroy_secrets[KEY_NAME]` to forcefully repopulate secrets for target encryption key
  def self.set_secrets(collected_secrets, exekube_cmd)
    return if collected_secrets.empty?

    FileUtils.mkdir_p Secrets::SECRETS_DIR
    FileUtils.mkdir_p Secrets::VALUES_DIR

    collected_secrets.each do |encryption_key, secrets|
      sh_filter "#{exekube_cmd} secrets-fetch #{encryption_key}"

      secrets_file = "./#{Secrets::SECRETS_DIR}/#{encryption_key}/#{Secrets::SECRETS_FILE}"

      begin
        if File.exist?(secrets_file)
          decrypted_secrets = YAML.load(File.read(secrets_file))
          decrypted_secrets.each do |secret_name, secret_value|
            ENV["TF_VAR_#{secret_name}"] = secret_value
          end
        else
          populated_secrets = {}
          secrets.each do |secret_name|
            if ENV[secret_name.upcase].to_s.empty?
              secret_value = SecureRandom.hex
            else
              secret_value = ENV[secret_name.upcase]
            end
            ENV["TF_VAR_#{secret_name}"] = secret_value
            populated_secrets[secret_name] = secret_value
          end
          puts "Secret file '#{secrets_file}' not found. I will create one."
          File.open(secrets_file, 'w') do |file|
            file.write(populated_secrets.to_yaml)
          end

          sh_filter "#{exekube_cmd} secrets-push #{encryption_key}"
        end
      rescue
        FileUtils.rm_f(secrets_file)
      end

      FileUtils.rm_f(secrets_file)
    end
  end
end

# vim: et ts=2 sw=2:
