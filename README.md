#Hiera Hierarchies and the Custom Facts Everyone Needs

For the last year and a half I've been representing Puppet as the Techinical Solutions Engineer covering all of the accounts headquartered in Silicon Valley.  This has been a fantastic opportunity to evangalize configuration management to both clients new and old.  One of the areas which I've noticed every new Puppet user runs into quite quickly is how to utilize Hiera effectively.  On a fresh install the hierarchy is pretty simple:

:hierarchy:
  - nodes/%{clientcert}
  - common

Basically a scapel or a shotgun.  Not exactly taking advantage of the power of the tool, but for a good reason, for any additional useful layers, custom facts are required.

On the plus side, Hiera, like nearly all of Puppet, is very customizable and can be tweaked to each individual organization's needs.  Unfortunately for new adopters, all of that power can be confusing and they look somewhere for direction.  Invariably I've noticed I nearly always recommend the same ideas so it seemed only fair to share those as a blog.

Hiera is powerful, but it has some limitations.  Notably there is a functional limit to the number of layers which can be added until performance begins to take a hit, and only one hierarchy can be used at a time for the entire node.  Because of this it makes sense to focus the hierarchy on generic concepts instead of specifically referencing unique items of the business unit or workflow.  The hierarchy which I've recommended the most is along the lines of this:

:hierarchy:
  - nodes/%{clientcert}
  - team/%{team}
  - application/%{application}
  - datacenter/%{datacenter}
  - common

The first objection I usually hear is something along the lines of "But we need a layer for X".  To that I challenge clients if they really need the additional layer or if it fits into one of the existing layers.  The vast majority of the differentiation they want tends to fit into the application layer.  Having a ton of different applications with some data overlap is preferable to having too many layers with too little differentation.

Quickly from there the conversation moves onto how to create the facts for %{team}, %{application} and %{datacenter}.  While there isn't a universal answer for how to create these facts, there is often one of a few possible methods that solve this problem for the vast majority of clients.

Ultimately the goal is to find a way which can programatically determine the answer to what is the X for this node?  To do this, we look to what pieces of information are already a part of or attached to the node.  I'll outline these appraoches below:

## Hostname
Sysadmins have been attaching metadata to servers for a very long time in the form of hostnames.  Many organizations still tag information such as datacenter, application and team in the name of the system.  Facter by default already creates a fact for hostname, so we can parse that existing fact to generate new facts.

These examples are custom ruby facts, they can be added into any module in the <module/lib/facter directory as .rb files and will be copied to all of the nodes via pluginsync and executed.  The first example here simply takes the first four characters and turns them into a new fact.

```ruby
Facter.add(:datacenter) do
  setcode do
    Facter.value(:hostname)[0..3]
  end
end
```

If we wanted to get the 5th character to the 8th, we could modify the 3rd line as follows:
```ruby
    Facter.value(:hostname)[4..7]
```

Or the 5th to the end of the line:
```ruby
    Facter.value(:hostname)[4..-1]
```

A more complicated example below which takes from the 6th character until there is a - or the end of the hostname, whichever comes first:
    Facter.value(:hostname)[5..-1][/(.*?)(\-|\z)/,1]


## Match value to table
This is ugly, but sometimes it's the best option, particularly when the only way to determine the datacenter is via IP address.  The shortcoming of this approach is that it requires the fact to be updated whenever there is new potential value.  Utilizing a known fact such as the ip network and case statements we can match up with a value such as datacenter.  Where avoidable, this shouldn't be used just to replace shorthand metadata with full names as it adds unnecessary complication (such as matching 'pdx' in the hostname and replacing with 'portland')

```ruby
Facter.add(:datacenter) do
  setcode do
    network=Facter.value(:network)
    case network
    when '10.0.2.0'
      'portland'
    when '10.0.3.0'
      'sydney'
    when '192.168.0.0'
      'home'
    else
      'unknown'
    end
  end
end
```

## Read Metadata
VMWare and AWS allow VMs to be tagged with metadata that can be read elsewhere.  Often times these types of tags are created already for the purpose of chargeback.  Those metadata tags can be turned into custom facts and used with Puppet as well.

xxxx

## Drop Facts File
When there is no programatic way to determine the appropriate value, Facter supports the creation of this type of metadata via the create of fact files in /etc/puppetlabs/facter/facts.d .  These files can be in yaml, jsonor txt format.  There can even be executable scripts in this directory as long as they return key value pairs.  Generally I consider txt to be easiest as it's simply:

key=value

There can be any number of files each with any number of key value pairs in them in this directory.  Different files can have different formats in the same directory as well.  The choice on how to break up facts between multiple files or conslidate them tends to relate more to how they are created.

Generally facts files work best when they are created at provisioning by the provisioning system.  Most workflows with vRA or UCS Director use this method to pass information from the provisioning system to Puppet.  It's relatively easy in any of these systems to create a file with the approriate values on the provisioned system, then install Puppet and let it handle the rest.  An example of a file which might get created is below:

facts.txt
```text
datacenter=portland
application=doc
team=TSE
```

## Conclusion
Hiera is one of the most powerful pieces of Puppet for enabling the reusability of code, but custom facts are a critical component to take advantage of it.  Starting with a sane but simple hierarchy and building a few simple custom facts can greatly accelerate the ability to adopt Puppet across your organization.
