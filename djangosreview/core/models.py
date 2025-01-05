from django.db import models


class Commentlog(models.Model):
    talk = models.ForeignKey('Talks', models.DO_NOTHING, db_column='talk', blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    state = models.CharField(blank=True, null=True)
    logdate = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'commentlog'


class ConfigOverrides(models.Model):
    event = models.ForeignKey('Events', models.DO_NOTHING, db_column='event', blank=True, null=True)
    nodename = models.CharField(blank=True, null=True)
    value = models.CharField()

    class Meta:
        managed = False
        db_table = 'config_overrides'
        verbose_name_plural = 'Config Overrides'


class Corrections(models.Model):
    talk = models.OneToOneField('Talks', models.DO_NOTHING, db_column='talk', primary_key=True)  # The composite primary key (talk, property) found, that is not supported. The first column is selected.
    property = models.ForeignKey('Properties', models.DO_NOTHING, db_column='property')
    property_value = models.CharField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'corrections'
        unique_together = (('talk', 'property'),)
        verbose_name_plural = 'Corrections'


class Events(models.Model):
    name = models.CharField()
    time_offset = models.IntegerField()
    inputdir = models.CharField(blank=True, null=True)
    outputdir = models.CharField(blank=True, null=True)

    def __str__(self):
        return self.name

    class Meta:
        managed = False
        db_table = 'events'
        verbose_name_plural = 'Events'


# class MojoMigrations(models.Model):
#     name = models.TextField(primary_key=True)
#     version = models.BigIntegerField()

#     class Meta:
#         managed = False
#         db_table = 'mojo_migrations'


class Properties(models.Model):
    name = models.CharField(blank=True, null=True)
    description = models.CharField(blank=True, null=True)
    helptext = models.CharField(blank=True, null=True)

    def __str__(self):
        return self.name

    class Meta:
        managed = False
        db_table = 'properties'
        verbose_name_plural = 'Properties'


class RawFiles(models.Model):
    filename = models.CharField(unique=True)
    room = models.ForeignKey('Rooms', models.DO_NOTHING, db_column='room')
    starttime = models.DateTimeField(blank=True, null=True)
    endtime = models.DateTimeField(blank=True, null=True)
    stream = models.CharField()
    mtime = models.IntegerField(blank=True, null=True)
    collection_name = models.CharField(blank=True, null=True)

    def __str__(self):
        return self.filename

    class Meta:
        managed = False
        db_table = 'raw_files'
        verbose_name_plural = 'RawFiles'


class Rooms(models.Model):
    name = models.CharField(blank=True, null=True)
    altname = models.CharField(blank=True, null=True)
    outputname = models.CharField(blank=True, null=True)

    def __str__(self):
        return self.name

    class Meta:
        managed = False
        db_table = 'rooms'
        verbose_name_plural = 'Rooms'


class Speakers(models.Model):
    email = models.CharField(blank=True, null=True)
    name = models.CharField()
    upstreamid = models.CharField(blank=True, null=True)
    event = models.ForeignKey(Events, models.DO_NOTHING, db_column='event', blank=True, null=True)

    def __str__(self):
        return self.name

    class Meta:
        managed = False
        db_table = 'speakers'
        verbose_name_plural = 'Speakers'


class SpeakersEvents(models.Model):
    speaker = models.ForeignKey(Speakers, models.DO_NOTHING, db_column='speaker')
    event = models.ForeignKey(Events, models.DO_NOTHING, db_column='event')
    upstreamid = models.CharField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'speakers_events'
        verbose_name_plural = 'Speakers Events'


class SpeakersTalks(models.Model):
    speaker = models.OneToOneField(Speakers, models.DO_NOTHING, db_column='speaker', primary_key=True)  # The composite primary key (speaker, talk) found, that is not supported. The first column is selected.
    talk = models.ForeignKey('Talks', models.DO_NOTHING, db_column='talk')

    class Meta:
        managed = False
        db_table = 'speakers_talks'
        unique_together = (('speaker', 'talk'),)
        verbose_name_plural = 'Speakers Talks'


class Talks(models.Model):
    room = models.ForeignKey(Rooms, models.DO_NOTHING, db_column='room')
    slug = models.CharField()
    nonce = models.CharField(unique=True)
    starttime = models.DateTimeField()
    endtime = models.DateTimeField()
    title = models.CharField()
    event = models.ForeignKey(Events, models.DO_NOTHING, db_column='event')
    state = models.CharField(choices=(
        ('waiting_for_files', 'waiting_for_files'),
        ('cutting', 'cutting'),
        ('generating_previews', 'generating_previews'),
        ('notification', 'notification'),
        ('preview', 'preview'),
        ('transcoding', 'transcoding'),
        ('fixuping', 'fixuping'),
        ('uploading', 'uploading'),
        ('publishing', 'publishing'),
        ('notify_final', 'notify_final'),
        ('finalreview', 'finalreview'),
        ('announcing', 'announcing'),
        ('transcribing', 'transcribing'),
        ('syncing', 'syncing'),
        ('done', 'done'),
        ('injecting', 'injecting'),
        ('remove', 'remove'),
        ('removing', 'removing'),
        ('broken', 'broken'),
        ('needs_work', 'needs_work'),
        ('lost', 'lost'),
        ('ignored', 'ignored'),
        ('uninteresting', 'uninteresting'),
    ))
    progress = models.CharField(choices=(
        ('waiting', 'waiting'),
        ('scheduled', 'scheduled'),
        ('running', 'running'),
        ('done', 'done'),
        ('failed', 'failed'),
    ))
    comments = models.TextField(blank=True, null=True)
    upstreamid = models.CharField(blank=True, null=True)
    subtitle = models.CharField(blank=True, null=True)
    prelen = models.DurationField(blank=True, null=True)
    postlen = models.DurationField(blank=True, null=True)
    track = models.ForeignKey('Tracks', models.DO_NOTHING, db_column='track', blank=True, null=True)
    reviewer = models.ForeignKey('Users', models.DO_NOTHING, db_column='reviewer', blank=True, null=True)
    perc = models.IntegerField(blank=True, null=True)
    apologynote = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    active_stream = models.CharField()
    flags = models.JSONField(blank=True, null=True)

    def __str__(self):
        return self.title

    class Meta:
        managed = False
        db_table = 'talks'
        unique_together = (('event', 'slug'),)
        verbose_name_plural = 'Talks'


class Tracks(models.Model):
    name = models.CharField(blank=True, null=True)
    email = models.CharField(blank=True, null=True)
    upstreamid = models.CharField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'tracks'
        verbose_name_plural = 'Tracks'


class Users(models.Model):
    email = models.CharField(unique=True, blank=True, null=True)
    password = models.TextField(blank=True, null=True)
    isadmin = models.BooleanField(blank=True, null=True)
    room = models.ForeignKey(Rooms, models.DO_NOTHING, db_column='room', blank=True, null=True)
    name = models.CharField(blank=True, null=True)
    isvolunteer = models.BooleanField(blank=True, null=True)

    def __str__(self):
        return self.email

    class Meta:
        managed = False
        db_table = 'users'
        verbose_name_plural = 'Users'
