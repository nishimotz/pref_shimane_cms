module AdvertisementHelper
  def fill_empty_cells(num)
    colomn_n = 3
    tds = ""
    res = num % colomn_n 
    unless res == 0
      (colomn_n - res).times do
        tds += "<td></td>\n"
      end
    end
    return tds
  end

  def job_exists?
    Job.find_by_action('move_banner_images')
  end

  def image_src(image_file)
    if @preview
      "/advertisement.data/#{image_file}"
    else
      "/images/advertisement/#{image_file}"
    end
  end
end
