require 'json'
require_relative 'cache'
require_relative 'renamer'
require_relative 'time_now'
require_relative 'unique_id'

class Starter

  def initialize
    @cache = Cache.new
  end

  # - - - - - - - - - - - - - - - - -
  # choices when setting up a cyber-dojo
  # - - - - - - - - - - - - - - - - -

  def custom_choices
    cache.of_display_names('custom')
  end

  def languages_choices
    cache.of_display_names('languages')
  end

  def exercises_choices
    cache.of_exercises
  end

  # - - - - - - - - - - - - - - - - -
  # manifests for given choices
  # - - - - - - - - - - - - - - - - -

  def custom_manifest(major_name, minor_name)
    major_minor_manifest(major_name, minor_name, 'custom')
  end

  # - - - - - - - - - - - - - - - - -

  def language_manifest(major_name, minor_name, exercise_name)
    instructions = cache.of_exercises[:contents][exercise_name]
    if instructions.nil?
      raise ArgumentError.new('exercise_name:invalid')
    end
    manifest = major_minor_manifest(major_name, minor_name, 'languages')
    manifest['visible_files']['instructions'] = instructions
    manifest['exercise'] = exercise_name
    manifest
  end

  # - - - - - - - - - - - - - - - - -

  def manifest(old_name)
    parts = old_name.split('-', 2)
    parts = Renamer.new.renamed(parts)
    major_name = parts[0]
    minor_name = parts[1]
    major_minor_manifest(major_name, minor_name, 'languages')
  end

  # - - - - - - - - - - - - - - - - -

  def method_missing(name, *_args, &_block)
    raise RuntimeError.new("#{name}:unknown_method")
  end

  private # = = = = = = = = = = = = =

  attr_reader :cache

  include TimeNow
  include UniqueId

  def major_minor_manifest(major_name, minor_name, dir_name)
    # [1] Issue: [] is not a valid progress_regex.
    # It needs two regexs.
    # This affects zipper.zip_tag()
    dir_cache = cache.of_dirs(dir_name)
    major = dir_cache[major_name]
    if major.nil?
      raise ArgumentError.new('major_name:invalid')
    end
    dir = major[minor_name]
    if dir.nil?
      raise ArgumentError.new('minor_name:invalid')
    end

    manifest = JSON.parse(IO.read("#{dir}/manifest.json"))

    manifest['id'] = unique_id
    manifest['created'] = time_now

    set_visible_files(dir, manifest)
    manifest['highlight_filenames'] ||= []
    set_lowlights_filenames(manifest)
    manifest['filename_extension'] ||= ''
    manifest['progress_regexs'] ||= []       # [1]
    manifest['highlight_filenames'] ||= []
    manifest['max_seconds'] ||= 10
    manifest['tab_size'] ||= 4
    manifest.delete('visible_filenames')
    manifest
  end

  # - - - - - - - - - - - - - - - - -

  def set_lowlights_filenames(manifest)
    manifest['lowlight_filenames'] =
      if manifest['highlight_filenames'].empty?
        ['cyber-dojo.sh', 'makefile', 'Makefile', 'unity.license.txt']
      else
        manifest['visible_filenames'] - manifest['highlight_filenames']
      end
  end

  # - - - - - - - - - - - - - - - - -

  def set_visible_files(dir, manifest)
    visible_filenames = manifest['visible_filenames']
    manifest['visible_files'] =
      Hash[visible_filenames.collect { |filename|
        [filename, IO.read("#{dir}/#{filename}")]
      }]
    manifest['visible_files']['output'] = ''
  end

end
