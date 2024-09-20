import Config

if config_env() not in [:prod] do
  Dotenv.load!()
end
