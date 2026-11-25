# vchord-cnpg

[vchord](https://github.com/pgsty/vchord) (the PGSTY-maintained VectorChord) packaged as
[CloudNativePG extension images](https://cloudnative-pg.io/docs/current/imagevolume_extensions/), for use with
the official `ghcr.io/cloudnative-pg/postgresql` images. PGSTY publishes `.deb` and `.zip` packages but no
container images; these images contain the files of the release's `.zip` package and nothing else.

```
ghcr.io/<owner>/vchord-cnpg:pg<postgres major>-v<vchord version>    e.g. pg19-v1.5.0
```

`linux/amd64` and `linux/arm64`. A daily workflow publishes every new vchord release for each PostgreSQL
major the release has packages for. Tags are never rebuilt.

## Layout

| Path | Contents |
|---|---|
| `/lib` | `vchord.so` |
| `/share/extension` | `vchord.control` and the SQL scripts, including every upgrade path |
| `/licenses/vchord` | the upstream licence |

This is CloudNativePG's default layout, so the cluster needs no paths:

```yaml
spec:
  imageCatalogRef:            # or imageName: ghcr.io/cloudnative-pg/postgresql:19.0-standard-trixie
    apiGroup: postgresql.cnpg.io
    kind: ClusterImageCatalog
    name: postgresql
    major: 19
  postgresql:
    shared_preload_libraries: ["vchord"]
    extensions:
      - name: vchord
        image:
          reference: ghcr.io/<owner>/vchord-cnpg:pg19-v1.5.0
```

vchord needs pgvector's `vector` extension, which the `standard` CloudNativePG images include. Image volumes
need a Kubernetes version and container runtime that support them; see the CloudNativePG documentation linked
above.

## Upgrading vchord

Change the tag, let CloudNativePG restart the instances, then in every database that has the extension:

```sql
ALTER EXTENSION vchord UPDATE;
```

Read the [release notes](https://github.com/pgsty/vchord/releases) first: some releases recommend a `REINDEX`.
Coming from `tensorchord/vchord-scratch`, drop the `dynamic_library_path` and `extension_control_path`
overrides that image needed.

## Build locally

```sh
./scripts/fetch.sh 1.5.0 19 out
docker buildx build --platform linux/amd64 --load -t vchord-cnpg:pg19-v1.5.0 .
```

## Licence

vchord is AGPL-3.0-only; its source is at <https://github.com/pgsty/vchord>. The build files in this
repository are under the same licence.
