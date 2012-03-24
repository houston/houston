# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


Project.destroy_all


unite = Project.create(name: "Unite", slug: "unite")

unite_dev = unite.environments.create(name: "PRI", slug: "dev")
unite_master = unite.environments.create(name: "Production", slug: "master")



tsatsiki = Project.create(name: "Tsatsiki", slug: "tsatsiki", git_url: "git://github.com/boblail/tsatsiki.git")

tsatsiki_dev = tsatsiki.environments.create(name: "PRI", slug: "dev")

tsatsiki_release1 = tsatsiki_dev.releases.create(name: "Upgrade Rails to 3.1",
  commit0: "8e0f2f6d32cfcbd2ee39a10da1dc568e9dcb30d1",
  commit1: "7cb53278a8f3577f43c38335793d88b992715839")
tsatsiki_release1.load_commits!
tsatsiki_release2 = tsatsiki_dev.releases.create(name: "Specification",
  commit0: "7cb53278a8f3577f43c38335793d88b992715839",
  commit1: "d3d1e7d9b40292071016b19fded67d051bf38615")
tsatsiki_release2.load_commits!



changelog = Project.create(name: "Change Log", slug: "changelog", git_url: Rails.root.to_s)

changelog_dev = changelog.environments.create(name: "PRI", slug: "dev")
changelog_master = changelog.environments.create(name: "Production", slug: "master")

