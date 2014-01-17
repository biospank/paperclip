module Versione
  # da modificare ogni qual volta esce una nuova versione
  RELEASE = '2.4.0'

  def last_release()
    @@__last_release ||= RELEASE.split('.').join().to_i
  end

  def current_version()
    @@__current_version ||= begin
      licenza = Models::Licenza.first
      licenza.versione.split('.').join().to_i
    end
  end

  def update_version!()
    if last_release >= current_version
      Models::Licenza.first.update_attribute(:versione, RELEASE)
      return true
    end

    return false
  end


end